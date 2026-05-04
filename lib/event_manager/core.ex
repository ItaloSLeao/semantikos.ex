defmodule EventManager.Core do
  @moduledoc "Core context consolidating Accounts and Events logic."
  import Ecto.Query
  alias EventManager.Repo
  alias EventManager.Schemas.{User, UserToken, Event, Registration}
  alias EventManager.UserNotifier

  ## --- ACCOUNTS ---

  def get_user_by_email(email) when is_binary(email), do: Repo.get_by(User, email: email)

  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id), do: id

  def get_user!(id), do: Repo.get!(User, id)

  def list_users_by_ids(ids) do
    ids = Enum.map(ids, &parse_id/1)
    from(u in User, where: u.id in ^ids) |> Repo.all()
  end

  def list_users(opts \\ []) do
    from(u in User, order_by: [asc: u.name])
    |> maybe_filter_role(opts[:role])
    |> Repo.all()
  end

  def list_admins, do: Repo.all(from u in User, where: u.role == :admin)
  def list_speakers, do: Repo.all(from u in User, where: u.role == :speaker)

  defp maybe_filter_role(q, nil), do: q
  defp maybe_filter_role(q, role), do: where(q, [u], u.role == ^role)

  def register_user(attrs), do: %User{} |> User.registration_changeset(attrs) |> Repo.insert()
  def register_admin(attrs), do: register_user(Map.put(attrs, :role, :admin))
  def register_speaker(attrs), do: register_user(Map.put(attrs, :role, :speaker))

  def change_user_email(user, attrs \\ %{}), do: User.email_changeset(user, attrs)
  def update_user_profile(user, attrs), do: user |> User.profile_changeset(attrs) |> Repo.update()
  def update_user_password(user, attrs), do: user |> User.password_changeset(attrs) |> Repo.update()

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    case UserToken.verify_session_token_query(token) |> Repo.one() do
      nil -> nil
      user -> user
    end
  end

  def delete_user_session_token(token),
    do: UserToken.by_token_and_context_query(token, "session") |> Repo.delete_all()

  def deliver_user_confirmation_instructions(user, confirmation_url_fun) do
    if user.confirmed_at, do: {:error, :already_confirmed}, else: do_confirm(user, confirmation_url_fun)
  end

  defp do_confirm(user, url_fun) do
    {token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, url_fun.(token))
  end

  def confirm_user(token) do
    case UserToken.verify_email_token_query(token, "confirm") |> Repo.one() do
      nil -> {:error, :invalid_token}
      user -> user |> User.confirm_changeset() |> Repo.update() |> confirm_result(user)
    end
  end

  defp confirm_result({:ok, user}, user), do: UserToken.delete_all_for_user(user, "confirm")
  defp confirm_result(error, _), do: error

  def deliver_user_reset_password_instructions(user, url_fun) do
    {token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, url_fun.(token))
  end

  def get_user_by_reset_password_token(token),
    do: UserToken.verify_email_token_query(token, "reset_password") |> Repo.one()

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  ## --- EVENTS ---

  def list_events(opts \\ []) do
    from(e in Event, preload: [:speaker, :registrations])
    |> filter_status(opts[:status])
    |> filter_speaker(opts[:speaker_id])
    |> filter_upcoming(opts[:upcoming_only])
    |> order_events(opts[:order_by] || {:date, :asc})
    |> paginate(opts[:page], opts[:per_page])
    |> Repo.all()
  end

  def get_event!(id), do: Event |> Repo.get!(id) |> Repo.preload([:speaker, :registrations])
  def get_event_with_registrations!(id), do: Event |> Repo.get!(id) |> Repo.preload([:speaker, registrations: [:user]])

  def create_event(attrs), do: %Event{} |> Event.changeset(attrs) |> Repo.insert()
  def update_event(%Event{} = event, attrs), do: event |> Event.changeset(attrs) |> Repo.update()
  def publish_event(%Event{} = event), do: event |> Event.publish_changeset() |> Repo.update()
  def cancel_event(%Event{} = event) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:event, Event.cancel_changeset(event))
    |> Ecto.Multi.run(:notifications, fn _repo, %{event: cancelled_event} ->
      # Notifica inscritos em tempo real via WebSocket antes de processar lógica pesada
      EventManagerWeb.Endpoint.broadcast(
        "event_notifications:#{cancelled_event.id}",
