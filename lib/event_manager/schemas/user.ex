defmodule EventManager.Schemas.User do
  @moduledoc """
  User schema and auth changesets.
  Implements role-based access control.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(student speaker admin)a

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :name, :string
    field :role, Ecto.Enum, values: @roles, default: :student
    field :course, :string
    field :department, :string
    field :cpf, :string
    field :birth_date, :date
    field :registration_id, :string
    field :avatar_path, :string
    field :confirmed_at, :utc_datetime

    has_many :registrations, EventManager.Schemas.Registration, on_delete: :delete_all
    has_many :events, EventManager.Schemas.Event, foreign_key: :speaker_id, on_delete: :nilify_all
    has_many :chat_messages, EventManager.Schemas.ChatMessage, on_delete: :delete_all
    has_many :certificates, EventManager.Schemas.Certificate, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :name, :role, :course, :department, :cpf, :birth_date, :registration_id])
    |> validate_required([:email, :password, :name])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, EventManager.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 4, max: 72)
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
