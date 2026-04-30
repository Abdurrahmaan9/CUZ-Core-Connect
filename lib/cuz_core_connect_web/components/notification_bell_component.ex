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

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if socket.assigns.initialized do
      {:ok, socket}
    else
      user = assigns.current_scope.user

      if connected?(socket) do
        CuzCoreConnectWeb.Endpoint.subscribe("notifications:#{user.id}")
      end

      notifications = Notifications.list_brief_notifications(user)
      unread_count = Notifications.count_unread(user.id)

      {:ok,
       socket
       |> assign(:notifications, notifications)
       |> assign(:unread_count, unread_count)
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
    notifications = Notifications.list_brief_notifications(socket.assigns.current_scope.user)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, 0)}
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    Notifications.mark_as_read(id)
    user = socket.assigns.current_scope.user
    notifications = Notifications.list_brief_notifications(user)
    unread_count = Notifications.count_unread(user.id)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)}
  end

  def handle_info(%{event: "new_notification", payload: _notification}, socket) do
    user = socket.assigns.current_scope.user
    notifications = Notifications.list_brief_notifications(user)
    unread_count = Notifications.count_unread(user.id)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)}
  end

  defp notification_icon("application"), do: "hero-building-storefront"
  defp notification_icon("system_message"), do: "hero-cog-6-tooth"
  defp notification_icon("document"), do: "hero-document-text"
  defp notification_icon(_), do: "hero-bell"

  defp notification_color("approved"), do: "text-emerald-600 bg-emerald-50"
  defp notification_color("rejected"), do: "text-red-600 bg-red-50"
  defp notification_color("pending_review"), do: "text-amber-600 bg-amber-50"
  defp notification_color(_), do: "text-blue-600 bg-blue-50"

  defp notifications_path(:admin), do: "/admin/notifications"
  defp notifications_path(:merchant), do: "/merchant/notifications"

  defp time_ago(nil), do: ""

  defp time_ago(datetime) do
    diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> "#{div(diff, 604_800)}w ago"
    end
  end

  def render(assigns) do
    ~H"""
    <div class="relative" id={@id} phx-target={@myself}>
      <button
        phx-click="toggle_bell"
        phx-target={@myself}
        class={[
          "relative p-2 rounded-full transition-all duration-200",
          if(@open,
            do: "text-primary",
            else: "text-base hover:text-primary"
          )
        ]}
        aria-label="Notifications"
      >
        <.icon name="hero-bell" class="w-6 h-6" />
        <span :if={@unread_count > 0} class="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-orange-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1 animate-pulse">
          {if @unread_count > 99, do: "99+", else: @unread_count}
        </span>
      </button>

      <%!-- Click outside overlay --%>
      <%= if @open do %>
        <div class="fixed inset-0 z-40" phx-click="close_bell" phx-target={@myself}></div>
      <% end %>

      <%!-- Dropdown panel --%>
      <%= if @open do %>
        <div class="absolute right-0 top-full mt-5 w-96 bg-base-100 rounded-lg shadow-xl border border-secondary/45 z-50 overflow-hidden">
          <div class="flex items-center justify-between px-4 py-3 border-b border-primary/20 bg-base-300/20">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-sm">Notifications</span>
              <%= if @unread_count > 0 do %>
                <span class="bg-orange-500 text-xs font-bold px-2 py-0.5 rounded-full">
                  {@unread_count} new
                </span>
              <% end %>
            </div>
            <div class="flex items-center gap-2">
              <%= if @unread_count > 0 do %>
                <button
                  phx-click="mark_all_read"
                  phx-target={@myself}
                  class="text-xs text-orange-600 hover:text-orange-700 font-medium transition-colors"
                >
                  Mark all read
                </button>
              <% end %>
            </div>
          </div>

          <%!-- Notifications list --%>
          <div class="max-h-80 overflow-y-auto divide-y divide-gray-50">
            <%= if @notifications == [] do %>
              <div class="flex flex-col items-center justify-center py-10">
                <.icon name="hero-bell-slash" class="w-10 h-10 mb-2 opacity-40" />
                <p class="text-sm">No notifications yet</p>
              </div>
            <% else %>
              <%= for notification <- @notifications do %>
                <div class={[
                  "flex gap-3 px-4 py-3 hover:bg-gray-50 transition-colors cursor-pointer group",
                  if(!notification.read,
                    do: "bg-orange-50/40 border-l-2 border-l-orange-400",
                    else: ""
                  )
                ]}>
                  <%!-- Icon --%>
                  <div class={[
                    "w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5",
                    notification_color(notification.status)
                  ]}>
                    <.icon name={notification_icon(notification.type)} class="w-4 h-4" />
                  </div>

                  <%!-- Content --%>
                  <div class="flex-1 min-w-0">
                    <p class={[
                      "text-sm leading-snug",
                      if(!notification.read, do: "font-medium text-base", else: "text-base-300")
                    ]}>
                      {notification.message}
                    </p>
                    <%= if notification.document_name do %>
                      <p class="text-xs mt-0.5 truncate">
                        {notification.document_name}
                      </p>
                    <% end %>
                    <p class="text-xs text-base-300 mt-1">{time_ago(notification.inserted_at)}</p>
                  </div>

                  <%!-- Actions --%>
                  <div class="flex flex-col items-end gap-1 flex-shrink-0">
                    <%= if !notification.read do %>
                      <button
                        phx-click="mark_read"
                        phx-value-id={notification.id}
                        phx-target={@myself}
                        class="w-2 h-2 bg-orange-400 rounded-full hover:bg-orange-500 transition-colors mt-1"
                        title="Mark as read"
                      >
                      </button>
                    <% end %>
                    <%= if notification.action_url do %>
                      <.link
                        navigate={notification.action_url}
                        phx-click="close_bell"
                        phx-target={@myself}
                        class="opacity-0 group-hover:opacity-100 transition-opacity"
                      >
                        <.icon
                          name="hero-arrow-top-right-on-square"
                          class="w-3.5 h-3.5 text-base-300 hover:text-orange-500"
                        />
                      </.link>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

          <%!-- Footer --%>
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
