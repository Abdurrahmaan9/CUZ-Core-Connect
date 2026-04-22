defmodule CuzCoreConnectWeb.Plugs.AdminAuth do
  @moduledoc """
  Authentication for admin users.

  This module contains functions for ensuring that only users with admin role
  can access admin routes and functionality.
  """

  import Phoenix.LiveView

  @doc """
  Ensures the current user has admin role.

  ## Usage

      on_mount [{CuzCoreConnectWeb.Plugs.UserAuth, :require_authenticated}, {CuzCoreConnectWeb.AdminAuth, :ensure_admin}]

  """
  def on_mount(:ensure_admin, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    case socket.assigns.current_scope do
      %{user: %{user_role: "Admin"}} ->
        {:cont, socket}

      %{user: _} ->
        {:halt,
         socket
         |> put_flash(:error, "Access denied. Admin privileges required.")
         |> redirect(to: signed_in_path(socket))}

      _ ->
        {:halt,
         socket
         |> put_flash(:error, "You must be logged in to access this page.")
         |> redirect(to: "/users/log-in")}
    end
  end

  def on_mount(:default, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      CuzCoreConnectWeb.Plugs.UserAuth.get_current_scope_from_session(session)
    end)
  end

  defp signed_in_path(socket) do
    case socket.assigns.current_scope do
      %{user: %{user_role: "Admin"}} -> "/Admin/Dashboard"
      _ -> "/users/settings"
    end
  end
end
