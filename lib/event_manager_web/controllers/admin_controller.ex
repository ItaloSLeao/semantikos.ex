defmodule EventManagerWeb.AdminController do
  @moduledoc """
  Controller for admin operations (events, users, reports, certificates).
  """
  use EventManagerWeb, :controller

  
  alias EventManager.Schemas.Event

  ## Event Management
  def events(conn, _params), do: render(conn, "events.html", events: EventManager.Core.list_events())

  def new_event(conn, _params) do
    render(conn, "event_new.html", changeset: Event.changeset(%Event{}, %{}), speakers: EventManager.Core.list_speakers())
  end

  def create_event(conn, %{"event" => event_params}) do
    # Garante um usuário no banco para evitar erro de Foreign Key no protótipo
    speaker_id = case EventManager.Repo.all(EventManager.Schemas.User) do
      [user | _] -> user.id
      [] ->
        {:ok, new_user} = EventManager.Core.register_speaker(%{
          name: "Palestrante Padrão",
          email: "palestrante@semanthikos.com",
          password: "SenhaSegura123!"
        })
        new_user.id
    end

    # Sobrescreve o speaker_id vindo do form com o ID válido
    event_params = Map.put(event_params, "speaker_id", speaker_id)

    case EventManager.Core.create_event(event_params) do
      {:ok, _event} ->
        conn
        |> put_flash(:info, "Evento criado com sucesso!")
        |> redirect(to: ~p"/events") # Redireciona direto para o catálogo para ver o resultado
      {:error, changeset} ->
        render(conn, "event_new.html", changeset: changeset, speakers: EventManager.Core.list_speakers())
    end
  end

  def edit_event(conn, %{"id" => id}) do
    event = EventManager.Core.get_event!(id)
    render(conn, "event_edit.html", event: event, changeset: Event.changeset(event, %{}), speakers: EventManager.Core.list_speakers())
  end

  def update_event(conn, %{"id" => id, "event" => event_params}) do
    event = EventManager.Core.get_event!(id)
    case EventManager.Core.update_event(event, event_params) do
      {:ok, event} -> conn |> put_flash(:info, "Evento atualizado com sucesso.") |> redirect(to: ~p"/admin/events/#{event.id}/edit")
      {:error, changeset} -> render(conn, "event_edit.html", event: event, changeset: changeset, speakers: EventManager.Core.list_speakers())
    end
  end

  def delete_event(conn, %{"id" => id}) do
    case EventManager.Core.delete_event(EventManager.Core.get_event!(id)) do
      {:ok, _} -> conn |> put_flash(:info, "Evento excluído com sucesso.") |> redirect(to: ~p"/admin/events")
      {:error, :has_registrations} -> conn |> put_flash(:error, "Não é possível excluir evento com inscrições.") |> redirect(to: ~p"/admin/events")
    end
  end

  def publish_event(conn, %{"id" => id}) do
    case EventManager.Core.publish_event(EventManager.Core.get_event!(id)) do
      {:ok, _} -> conn |> put_flash(:info, "Evento publicado com sucesso.") |> redirect(to: ~p"/admin/events/#{id}/edit")
      {:error, _} -> conn |> put_flash(:error, "Erro ao publicar evento.") |> redirect(to: ~p"/admin/events/#{id}/edit")
    end
  end
