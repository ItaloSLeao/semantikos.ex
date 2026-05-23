defmodule EventManagerWeb.EventChatLive do
  @moduledoc "LiveView for event chat with Q&A."
  use EventManagerWeb, :live_view
  

  @impl true
  def mount(%{"id" => event_id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(EventManager.PubSub, "event_chat:#{event_id}")

    current_user = socket.assigns.current_user

    messages = EventManager.Services.list_event_chat_messages(event_id, limit: 100)
    |> Enum.map(fn msg ->
      %{
        id: msg.id,
        user_id: msg.user_id,
        message: msg.message,
        user_name: if(msg.user, do: msg.user.name, else: "Anon"),
        sent_at: msg.sent_at,
        is_question: msg.is_question,
        is_answered: msg.is_answered
      }
    end)

    {:ok, 
      socket
      |> assign(
        event: EventManager.Core.get_event!(event_id),
        message_input: "",
        is_question: false,
        current_user: current_user
      )
      |> stream(:messages, messages)
    }
  end

  @impl true
  def handle_event("validate", %{"message" => msg}, socket) do
    {:noreply, assign(socket, message_input: msg)}
  end
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("send_message", params, socket) do
    msg = params["message"]
    is_q = params["is_question"] == "true"
    
    if msg && String.trim(msg) != "" do
      attrs = %{
