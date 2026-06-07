defmodule EventManagerWeb.CertificateController do
  @moduledoc """
  Controller for certificate viewing and downloading.
  """
  use EventManagerWeb, :controller


  def index(conn, _params) do
    user = conn.assigns.current_user
    certificates = EventManager.Services.list_user_certificates(user.id)

    render(conn, :index, certificates: certificates)
  end

  def show(conn, %{"id" => id}) do
    certificate = EventManager.Services.get_certificate!(id)
    user = conn.assigns.current_user

    if certificate.user_id == user.id do
      render(conn, :show, certificate: certificate)
    else
      conn
      |> put_flash(:error, "Você não tem permissão para acessar este certificado.")
      |> redirect(to: ~p"/my/certificates")
    end
  end

  def download(conn, %{"id" => id}) do
