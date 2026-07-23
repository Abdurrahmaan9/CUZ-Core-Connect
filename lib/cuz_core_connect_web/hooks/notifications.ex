defmodule CuzCoreConnectWeb.Hooks.Notifications do
  @moduledoc """
  Subscribes the LiveView process to the current user's notification topic and
  refreshes the top-nav bell when new notifications arrive.

  LiveComponents share the parent LiveView process, so PubSub messages must be
  handled here (not in `NotificationBellComponent.handle_info/2`).
  """
  import Phoenix.LiveView

  alias CuzCoreConnectWeb.NotificationBellComponent

  def on_mount(:default, _params, _session, socket) do
    socket =
      case socket.assigns do
        %{current_scope: %{user: %{id: user_id}}} when not is_nil(user_id) ->
          if connected?(socket) do
            CuzCoreConnectWeb.Endpoint.subscribe("notifications:#{user_id}")

            attach_hook(socket, :notification_bell, :handle_info, &handle_notification_info/2)
          else
            socket
          end

        _ ->
          socket
      end

    {:cont, socket}
  end

  defp handle_notification_info(%{event: "new_notification", payload: _notification}, socket) do
    send_update(NotificationBellComponent, id: "user-notification-bell", refresh: true)
    {:halt, socket}
  end

  defp handle_notification_info(_msg, socket), do: {:cont, socket}
end
