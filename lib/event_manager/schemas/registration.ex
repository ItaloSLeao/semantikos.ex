defmodule EventManager.Schemas.Registration do
  @moduledoc """
  Registration schema for event participation.
  Tracks user event registrations with attendance status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "registrations" do
    field :registered_at, :utc_datetime
    field :attended, :boolean, default: false
    field :attendance_marked_at, :utc_datetime
    field :notes, :string
    field :status, Ecto.Enum, values: [:confirmed, :waitlisted, :cancelled], default: :confirmed

    belongs_to :user, EventManager.Schemas.User
    belongs_to :event, EventManager.Schemas.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(registration, attrs) do
    registration
    |> cast(attrs, [:user_id, :event_id, :attended, :attendance_marked_at, :notes, :registered_at, :status])
    |> validate_required([:user_id, :event_id])
    |> default_registered_at()
    |> unique_constraint([:user_id, :event_id], name: :registrations_user_event_index)
