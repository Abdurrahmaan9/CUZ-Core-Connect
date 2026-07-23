defmodule CuzCoreConnectWeb.UserLive.Notifications do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Notifications

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Notifications")
     |> assign(:current_page, :notifications)
     |> assign(:filter, "all")
     |> load_notifications(user.id, "all")}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> load_notifications(user_id, filter)}
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    Notifications.mark_as_read(id)
    user_id = socket.assigns.current_scope.user.id

    {:noreply, load_notifications(socket, user_id, socket.assigns.filter)}
  end

  def handle_event("mark_all_read", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    Notifications.mark_all_as_read(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "All notifications marked as read.")
     |> load_notifications(user_id, socket.assigns.filter)}
  end

  defp load_notifications(socket, user_id, filter) do
    params =
      case filter do
        "unread" -> %{"read" => "unread"}
        "read" -> %{"read" => "read"}
        _ -> %{}
      end

    page = Notifications.list_notifications(user_id, Map.put(params, "per_page", 50))

    socket
    |> assign(:notifications, page.entries)
    |> assign(:unread_count, Notifications.count_unread(user_id))
  end

  defp notification_icon("application"), do: "hero-clipboard-document-check"
  defp notification_icon("system_message"), do: "hero-megaphone"
  defp notification_icon("document"), do: "hero-document-text"
  defp notification_icon(_), do: "hero-bell"

  defp status_badge("approved"), do: "badge-success"
  defp status_badge("rejected"), do: "badge-error"
  defp status_badge("pending_review"), do: "badge-warning"
  defp status_badge("alert"), do: "badge-warning"
  defp status_badge(_), do: "badge-info"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <.header>
        Notifications
        <:subtitle>System alerts kept in sync with email notices</:subtitle>
        <:actions>
          <button
            :if={@unread_count > 0}
            type="button"
            phx-click="mark_all_read"
            class="btn btn-sm btn-outline"
          >
            Mark all read
          </button>
        </:actions>
      </.header>

      <div class="flex flex-wrap gap-2 mb-4">
        <button
          :for={filter <- [{"all", "All"}, {"unread", "Unread"}, {"read", "Read"}]}
          type="button"
          phx-click="filter"
          phx-value-filter={elem(filter, 0)}
          class={[
            "btn btn-sm",
            @filter == elem(filter, 0) && "btn-primary",
            @filter != elem(filter, 0) && "btn-ghost"
          ]}
        >
          {elem(filter, 1)}
        </button>
      </div>

      <div class="rounded-2xl border border-base-300 bg-base-100 overflow-hidden">
        <%= if @notifications == [] do %>
          <div class="flex flex-col items-center justify-center py-16 text-base-content/50">
            <.icon name="hero-bell-slash" class="size-12 mb-3 opacity-40" />
            <p>No notifications in this filter.</p>
          </div>
        <% else %>
          <div class="divide-y divide-base-200">
            <div
              :for={notification <- @notifications}
              id={"notification-#{notification.id}"}
              class={[
                "flex gap-4 px-5 py-4",
                !notification.read && "bg-primary/5"
              ]}
            >
              <div class="mt-1 rounded-full bg-base-200 p-2">
                <.icon name={notification_icon(notification.type)} class="size-5" />
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <span class={["badge badge-sm capitalize", status_badge(notification.status)]}>
                    {String.replace(notification.status || "info", "_", " ")}
                  </span>
                  <span :if={!notification.read} class="badge badge-sm badge-warning">Unread</span>
                </div>
                <p class="mt-1 text-sm font-medium text-base-content">{notification.message}</p>
                <p :if={notification.document_name} class="text-xs text-base-content/50 mt-0.5">
                  {notification.document_name}
                </p>
                <p :if={notification.sender_name} class="text-xs text-base-content/40 mt-1">
                  From {notification.sender_name}
                </p>
                <p class="text-xs text-base-content/40 mt-1">
                  {Calendar.strftime(notification.inserted_at, "%b %d, %Y at %H:%M")}
                </p>
              </div>

              <div class="flex flex-col items-end gap-2 shrink-0">
                <.link
                  :if={notification.action_url}
                  href={notification.action_url}
                  class="btn btn-ghost btn-sm btn-square text-info"
                  title="Open"
                >
                  <.icon name="hero-arrow-top-right-on-square" class="size-5" />
                </.link>
                <button
                  :if={!notification.read}
                  type="button"
                  phx-click="mark_read"
                  phx-value-id={notification.id}
                  class="btn btn-ghost btn-xs"
                >
                  Mark read
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.user>
    """
  end
end
