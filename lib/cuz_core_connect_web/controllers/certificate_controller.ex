defmodule CuzCoreConnectWeb.CertificateController do
  @moduledoc """
  Serves a printable HTML Proof of Registration for fully-approved
  registrations. Accessible by registration id (authenticated owner/staff)
  or by tracking number for approved registrations (same knowledge as the
  public tracking page).
  """
  use CuzCoreConnectWeb, :controller

  alias CuzCoreConnect.Registrations

  @staff_roles ~w(admin academics finance hod retention)

  def show(conn, %{"id" => id}) do
    with registration when not is_nil(registration) <- Registrations.get_registration(id),
         true <- registration.registration_status == "APPROVED",
         :ok <- authorize_by_id(conn, registration) do
      render_proof(conn, registration)
    else
      _ ->
        unavailable(conn)
    end
  end

  def show_by_tracking(conn, %{"tracking_number" => tracking_number}) do
    case Registrations.get_registration_by_tracking_number(String.trim(tracking_number)) do
      %{registration_status: "APPROVED"} = registration ->
        render_proof(conn, registration)

      _ ->
        unavailable(conn)
    end
  end

  defp render_proof(conn, registration) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> put_view(CuzCoreConnectWeb.CertificateHTML)
    |> render(:show,
      page_title: "Proof of Registration",
      registration: registration
    )
  end

  defp authorize_by_id(conn, registration) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    cond do
      is_nil(user) ->
        :error

      user.user_role in @staff_roles ->
        :ok

      owns_registration?(user, registration) ->
        :ok

      true ->
        :error
    end
  end

  defp owns_registration?(user, registration) do
    Registrations.owns_registration?(user, registration)
  end

  defp unavailable(conn) do
    conn
    |> put_flash(:error, "Proof of registration is not available.")
    |> redirect(to: ~p"/")
  end
end
