defmodule EventManager.Services do
  @moduledoc "Services context consolidating Notifications, Certificates, and Reports logic."
  import Ecto.Query
  alias EventManager.Repo
  alias EventManager.Schemas.{ChatMessage, Certificate, Event, Registration, User}

  ## --- CHAT & NOTIFICATIONS ---

  def create_chat_message(attrs) do
    %ChatMessage{} |> ChatMessage.changeset(attrs) |> Repo.insert() |> broadcast()
  end

  def list_event_chat_messages(event_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    from(m in ChatMessage, where: m.event_id == ^event_id, preload: [:user],
         order_by: [asc: m.sent_at], limit: ^limit) |> Repo.all()
  end

  def mark_question_answered(message_id) do
    Repo.get!(ChatMessage, message_id) |> ChatMessage.answer_changeset() |> Repo.update() |> broadcast()
  end

  defp broadcast({:ok, msg}) do
    msg = Repo.preload(msg, :user)
    EventManagerWeb.Endpoint.broadcast("event_chat:#{msg.event_id}", "new_message", %{
      id: msg.id, message: msg.message, user_name: msg.user && msg.user.name,
      sent_at: msg.sent_at, is_question: msg.is_question, is_answered: msg.is_answered
    })
    {:ok, msg}
  end
  defp broadcast(error), do: error

  def broadcast_event_notification(event_id, type, data),
    do: EventManagerWeb.Endpoint.broadcast("event_notifications:#{event_id}", type, data)

  def broadcast_capacity_warning(event_id, remaining_seats),
    do: broadcast_event_notification(event_id, "capacity_warning", %{remaining_seats: remaining_seats})

  def broadcast_event_reminder(event_id, minutes_until),
    do: broadcast_event_notification(event_id, "event_reminder", %{minutes_until: minutes_until})

  ## --- CERTIFICATES ---

  def generate_certificate(user_id, event_id, type \\ :participation) do
    %Certificate{} |> Certificate.changeset(%{user_id: user_id, event_id: event_id, certificate_type: type})
    |> Repo.insert() |> then(&generate_pdf_data/1)
  end

  def generate_event_certificates(event_id) do
    EventManager.Core.list_event_registrations(event_id)
    |> Enum.filter(& &1.attended)
    |> Enum.map(&generate_certificate(&1.user_id, event_id, :participation))
    |> Enum.filter(&match?({:ok, _}, &1)) |> length()
  end

  defp generate_pdf_data({:ok, cert}) do
    user = Repo.get!(User, cert.user_id)
    event = Repo.get!(Event, cert.event_id) |> Repo.preload(:speaker)
    cert |> Ecto.Changeset.change(pdf_data: build_certificate_pdf(user, event, cert)) |> Repo.update()
  end
  defp generate_pdf_data(error), do: error

  def build_certificate_pdf(user, event, cert) do
    """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700;900&family=Playfair+Display:ital,wght@0,400;0,600;1,400&family=Montserrat:wght@400;500;600&display=swap');
      @page { size: A4 landscape; margin: 0; }
      body {
        margin: 0; padding: 0;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        background-color: #e2e8f0;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
      }
      .certificate-wrapper {
        box-sizing: border-box;
        background-color: #ffffff;
        background-image: 
          radial-gradient(circle at center, rgba(212, 175, 55, 0.08) 0%, transparent 60%),
          repeating-linear-gradient(45deg, rgba(26, 54, 93, 0.03) 0px, rgba(26, 54, 93, 0.03) 1px, transparent 1px, transparent 10px),
          repeating-linear-gradient(-45deg, rgba(212, 175, 55, 0.04) 0px, rgba(212, 175, 55, 0.04) 1px, transparent 1px, transparent 10px);
        position: relative;
        overflow: hidden;
      }
      @media screen {
        .certificate-wrapper {
          width: 297mm; height: 210mm;
          padding: 12mm;
          box-shadow: 0 20px 50px rgba(0,0,0,0.3);
          margin: 20px;
        }
      }
      @media print {
        body { background-color: #ffffff; display: block; }
        .certificate-wrapper {
          width: 100vw; height: 100vh;
          padding: 10mm;
          margin: 0;
          box-shadow: none;
        }
      }

      .certificate-border {
        position: relative;
        width: 100%; height: 100%;
        border: 12px solid #1a365d;
        box-sizing: border-box;
        padding: 10px;
      }
      .certificate-inner-border {
        width: 100%; height: 100%;
        border: 4px solid #d4af37;
        box-sizing: border-box;
        padding: 30px 50px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        align-items: center;
        background: rgba(255, 255, 255, 0.92);
        box-shadow: inset 0 0 60px rgba(212, 175, 55, 0.15);
        position: relative;
      }

      .corner { position: absolute; width: 45px; height: 45px; border: 5px solid #d4af37; }
      .corner-tl { top: -5px; left: -5px; border-right: none; border-bottom: none; }
      .corner-tr { top: -5px; right: -5px; border-left: none; border-bottom: none; }
      .corner-bl { bottom: -5px; left: -5px; border-right: none; border-top: none; }
      .corner-br { bottom: -5px; right: -5px; border-left: none; border-top: none; }

      .header {
        font-family: 'Cinzel', serif;
        font-size: 50px;
        color: #1a365d;
        letter-spacing: 14px;
        margin-top: 10px;
        margin-bottom: 0px;
        text-transform: uppercase;
        font-weight: 900;
        text-shadow: 1px 1px 0 rgba(212, 175, 55, 0.5);
      }
      .subtitle {
        font-family: 'Montserrat', sans-serif;
        font-size: 16px;
        color: #d4af37;
        letter-spacing: 8px;
        text-transform: uppercase;
        margin-bottom: 25px;
        font-weight: 700;
      }
      .content {
        font-family: 'Playfair Display', serif;
        font-size: 20px;
        line-height: 1.6;
        color: #2d3748;
        text-align: center;
        max-width: 85%;
        z-index: 2;
      }
      .recipient {
        font-family: 'Cinzel', serif;
        font-size: 40px;
        color: #1a365d;
        font-weight: 700;
        margin: 15px 0;
        border-bottom: 2px solid #d4af37;
        padding-bottom: 4px;
        display: inline-block;
      }
      .event-title {
        font-family: 'Montserrat', sans-serif;
        font-size: 24px;
        color: #1a365d;
        font-weight: 700;
        margin: 10px 0;
        text-transform: uppercase;
      }
      .footer-grid {
        width: 100%;
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
