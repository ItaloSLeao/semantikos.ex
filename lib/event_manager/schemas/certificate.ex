defmodule EventManager.Schemas.Certificate do
  @moduledoc """
  Certificate schema for event participation.
  Generates unique certificate numbers and stores PDF data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "certificates" do
    field :certificate_number, :string
    field :certificate_type, Ecto.Enum, values: [:participation, :speaker, :organizer], default: :participation
    field :generated_at, :utc_datetime
    field :pdf_data, :binary
    field :verified, :boolean, default: false

    belongs_to :user, EventManager.Schemas.User
    belongs_to :event, EventManager.Schemas.Event

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(certificate, attrs) do
    certificate
    |> cast(attrs, [:user_id, :event_id, :certificate_type, :pdf_data, :verified])
    |> validate_required([:user_id, :event_id])
