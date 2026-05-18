defmodule EventManager.Schemas.Event do
  @moduledoc """
  Event schema for academic events management.
  Supports seat limits, speaker assignment, and status tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @statuses ~w(draft published ongoing completed cancelled)a

  schema "events" do
    field :title, :string
    field :description, :string
    field :date, :utc_datetime
    field :duration_minutes, :integer, default: 60
    field :location, :string
    field :max_seats, :integer
    field :status, Ecto.Enum, values: @statuses, default: :published
    field :image_url, :string
    field :is_online, :boolean, default: false
    field :online_url, :string
    field :tags, {:array, :string}, default: []

    belongs_to :speaker, EventManager.Schemas.User
    has_many :registrations, EventManager.Schemas.Registration, on_delete: :delete_all
    has_many :chat_messages, EventManager.Schemas.ChatMessage, on_delete: :delete_all
    has_many :certificates, EventManager.Schemas.Certificate, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :description,
      :date,
      :duration_minutes,
      :location,
      :max_seats,
      :status,
      :speaker_id,
      :image_url,
      :is_online,
      :online_url,
      :tags
    ])
    |> validate_required([:title, :description, :date, :location, :max_seats])
    |> validate_number(:max_seats, greater_than: 0, less_than: 10_000)
    |> validate_number(:duration_minutes, greater_than: 0, less_than: 1440)
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:description, max: 5000)
    |> validate_future_date()
    |> validate_online_url_if_online()
    |> foreign_key_constraint(:speaker_id)
  end

  @doc "Changeset for publishing an event"
  def publish_changeset(event) do
    event
