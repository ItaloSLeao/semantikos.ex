defmodule EventManager.Schemas.UserToken do
  @moduledoc """
  UserToken schema for session and email tokens.
  """
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, EventManager.Schemas.User

    timestamps(updated_at: false)
  end

  @doc "Builds a session token for the user"
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{token: hashed_token, context: "session", user_id: user.id}}
  end

  @doc "Verifies session token query"
  def verify_session_token_query(token) do
    query =
      from t in __MODULE__,
        where: t.context == "session",
        where: t.token == ^:crypto.hash(@hash_algorithm, Base.url_decode64!(token, padding: false)),
        join: user in assoc(t, :user),
        select: user

    query
  end

  @doc "Builds an email token for confirmation or password reset"
  def build_email_token(user, context) do
    token = :crypto.strong_rand_bytes(@rand_size)
