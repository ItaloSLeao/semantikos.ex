defmodule EventManagerWeb.EventController do
  @moduledoc """
  Controller for event operations (viewing, registration, user registrations, speaker operations).
  Consolidates EventController, RegistrationController, and SpeakerController.
  """
  use EventManagerWeb, :controller

  alias EventManager.Schemas.Event

  # --- Public Event Viewing ---
  def index(conn, _params) do
    events = EventManager.Core.list_events(
      status: :published,
      upcoming_only: true,
      order_by: {:date, :asc}
    )
    render(conn, :index, events: events)
  end

  def show(conn, %{"id" => id}) do
    event = EventManager.Core.get_event_with_registrations!(id)
    current_user = conn.assigns[:current_user]
    registration = current_user && EventManager.Core.get_registration(id, current_user.id)

    render(conn, :show,
      event: event,
      registration: registration,
      remaining_seats: Event.remaining_seats(event)
    )
  end

  # --- Registration ---
  def register(conn, %{"id" => event_id}) do
    user = conn.assigns.current_user
    event_id_int = if is_binary(event_id), do: String.to_integer(event_id), else: event_id

    case EventManager.Core.register_for_event(event_id_int, user.id) do
      {:ok, _registration} ->
        conn |> put_flash(:info, "Inscrição realizada com sucesso!") |> redirect(to: ~p"/events/#{event_id}")
      {:error, :no_seats_available} ->
        conn |> put_flash(:error, "Evento está cheio. Não há mais vagas disponíveis.") |> redirect(to: ~p"/events/#{event_id}")
      {:error, _} ->
        conn |> put_flash(:error, "Erro ao realizar inscrição. Tente novamente.") |> redirect(to: ~p"/events/#{event_id}")
    end
  end

  def cancel_registration(conn, %{"id" => event_id}) do
    user = conn.assigns.current_user
    event_id_int = if is_binary(event_id), do: String.to_integer(event_id), else: event_id

    case EventManager.Core.cancel_registration(event_id_int, user.id) do
      {:ok, :cancelled} ->
        conn |> put_flash(:info, "Inscrição cancelada com sucesso.") |> redirect(to: ~p"/events/#{event_id}")
