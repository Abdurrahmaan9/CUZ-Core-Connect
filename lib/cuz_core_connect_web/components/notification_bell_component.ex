defmodule CuzCoreConnectWeb.NotificationBellComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Notifications

  def mount(socket) do
    {:ok,
     socket
     |> assign(:open, false)
     |> assign(:notifications, [])
     |> assign(:unread_count, 0)
     |> assign(:initialized, false)}
  end

  def update(%{refresh: true} = assigns, socket) do
    socket = assign(socket, Map.delete(assigns, :refresh))
    {:ok, reload_notifications(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if socket.assigns.initialized do
      {:ok, socket}
    else
      {:ok,
       socket
       |> reload_notifications()
       |> assign(:initialized, true)}
    end
  end

  def handle_event("toggle_bell", _params, socket) do
    {:noreply, update(socket, :open, &(!&1))}
  end

  def handle_event("close_bell", _params, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  def handle_event("mark_all_read", _params, socket) do
    Notifications.mark_all_as_read(socket.assigns.current_scope.user.id)

    {:noreply,
     socket
     |> reload_notifications()
     |> assign(:unread_count, 0)}
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    Notifications.mark_as_read(id)
    {:noreply, reload_notifications(socket)}
  end

  defp reload_notifications(socket) do
    user = socket.assigns.current_scope.user

    socket
    |> assign(:notifications, Notifications.list_brief_notifications(user))
    |> assign(:unread_count, Notifications.count_unread(user.id))
  end

  defp notification_icon("application"), do: "hero-clipboard-document-check"
  defp notification_icon("system_message"), do: "hero-megaphone"
  defp notification_icon("document"), do: "hero-document-text"
  defp notification_icon(_), do: "hero-bell"

  defp notification_color("approved"), do: "text-emerald-600 bg-emerald-50"
  defp notification_color("rejected"), do: "text-red-600 bg-red-50"
  defp notification_color("pending_review"), do: "text-amber-600 bg-amber-50"
  defp notification_color("alert"), do: "text-orange-600 bg-orange-50"
  defp notification_color("success"), do: "text-emerald-600 bg-emerald-50"
  defp notification_color(_), do: "text-blue-600 bg-blue-50"

  defp notifications_path(_role), do: ~p"/users/notifications"

  defp time_ago(nil), do: ""

  defp time_ago(%NaiveDateTime{} = datetime) do
    diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime)
    format_diff(diff)
  end

  defp time_ago(%DateTime{} = datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime)
    format_diff(diff)
  end

  defp format_diff(diff) when diff < 60, do: "just now"
  defp format_diff(diff) when diff < 3600, do: "#{div(diff, 60)}m ago"
  defp format_diff(diff) when diff < 86400, do: "#{div(diff, 3600)}h ago"
  defp format_diff(diff) when diff < 604_800, do: "#{div(diff, 86400)}d ago"
  defp format_diff(diff), do: "#{div(diff, 604_800)}w ago"

  def render(assigns) do
    ~H"""
    <div class="relative" id={@id} phx-click-away="close_bell" phx-target={@myself}>
      <button
        type="button"
        phx-click="toggle_bell"
        phx-target={@myself}
        class={[
          "relative p-2 rounded-full transition-all duration-200",
          if(@open, do: "text-primary", else: "text-base hover:text-primary")
        ]}
        aria-label="Notifications"
      >
        <.icon name="hero-bell" class="w-6 h-6" />
        <span
          :if={@unread_count > 0}
          class="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-orange-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1 animate-pulse"
        >
          {if @unread_count > 99, do: "99+", else: @unread_count}
        </span>
      </button>

      <%= if @open do %>
        <div class="absolute right-0 top-full mt-3 w-96 bg-base-100 rounded-lg shadow-xl border border-secondary/45 z-50 overflow-hidden">
          <div class="flex items-center justify-between px-4 py-3 border-b border-primary/20 bg-base-300/20">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-sm">Notifications</span>
              <%= if @unread_count > 0 do %>
                <span class="bg-orange-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">
                  {@unread_count} new
                </span>
              <% end %>
            </div>
            <%= if @unread_count > 0 do %>
              <button
                type="button"
                phx-click="mark_all_read"
                phx-target={@myself}
                class="text-xs text-orange-600 hover:text-orange-700 font-medium transition-colors"
              >
                Mark all read
              </button>
            <% end %>
          </div>

          <div class="max-h-80 overflow-y-auto divide-y divide-base-200">
            <%= if @notifications == [] do %>
              <div class="flex flex-col items-center justify-center py-10">
                <.icon name="hero-bell-slash" class="w-10 h-10 mb-2 opacity-40" />
                <p class="text-sm text-base-content/60">No notifications yet</p>
              </div>
            <% else %>
              <%= for notification <- @notifications do %>
                <div class={[
                  "flex gap-3 px-4 py-3 hover:bg-base-200/60 transition-colors group",
                  !notification.read && "bg-orange-50/40 border-l-2 border-l-orange-400"
                ]}>
                  <div class={[
                    "w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5",
                    notification_color(notification.status)
                  ]}>
                    <.icon name={notification_icon(notification.type)} class="w-4 h-4" />
                  </div>

                  <div class="flex-1 min-w-0">
                    <%= if notification.action_url do %>
                      <.link
                        href={notification.action_url}
                        phx-click="mark_read"
                        phx-value-id={notification.id}
                        phx-target={@myself}
                        class={[
                          "text-sm leading-snug block",
                          if(!notification.read,
                            do: "font-medium text-base-content",
                            else: "text-base-content/70"
                          )
                        ]}
                      >
                        {notification.message}
                      </.link>
                    <% else %>
                      <p class={[
                        "text-sm leading-snug",
                        if(!notification.read,
                          do: "font-medium text-base-content",
                          else: "text-base-content/70"
                        )
                      ]}>
                        {notification.message}
                      </p>
                    <% end %>
                    <%= if notification.document_name do %>
                      <p class="text-xs mt-0.5 truncate text-base-content/50">
                        {notification.document_name}
                      </p>
                    <% end %>
                    <p class="text-xs text-base-content/40 mt-1">
                      {time_ago(notification.inserted_at)}
                    </p>
                  </div>

                  <div class="flex flex-col items-end gap-1 flex-shrink-0">
                    <%= if !notification.read do %>
                      <button
                        type="button"
                        phx-click="mark_read"
                        phx-value-id={notification.id}
                        phx-target={@myself}
                        class="w-2 h-2 bg-orange-400 rounded-full hover:bg-orange-500 transition-colors mt-1"
                        title="Mark as read"
                      >
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

          <div class="px-4 py-3 border-t border-primary/20 bg-base-300/20">
            <.link
              navigate={notifications_path(@role)}
              phx-click="close_bell"
              phx-target={@myself}
              class="block text-center text-sm text-orange-600 hover:text-orange-700 font-medium transition-colors"
            >
              View all notifications
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
