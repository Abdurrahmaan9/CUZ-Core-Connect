defmodule CuzCoreConnectWeb.Admin.EmailLogs do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Communications

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Email Logs",
       current_page: :email_logs,
       filter: "all",
       selected_id: nil
     )
     |> load_logs()}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:filter, status) |> load_logs()}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_id, String.to_integer(id))}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected_id, nil)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    log = Communications.get_email_log!(id)

    case Communications.delete_email_log(log) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Email log deleted.")
         |> assign(:selected_id, nil)
         |> load_logs()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete email log.")}
    end
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp load_logs(socket) do
    logs =
      case socket.assigns.filter do
        "all" -> Communications.list_email_logs()
        status -> Communications.list_email_logs_by_status(status)
      end

    socket
    |> assign(:logs, logs)
    |> assign(:stats, Communications.email_log_stats())
  end

  defp status_badge("sent"), do: "badge-success"
  defp status_badge("failed"), do: "badge-error"
  defp status_badge(_), do: "badge-ghost"

  defp mode_label(true), do: "API"
  defp mode_label(false), do: "Local"
  defp mode_label(_), do: "—"

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y, %H:%M")
  defp format_datetime(_), do: "—"

  @impl true
  def render(assigns) do
    selected = Enum.find(assigns.logs, &(&1.id == assigns.selected_id))
    assigns = assign(assigns, :selected, selected)

    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <div class="space-y-6">
        <div>
          <h1 class="text-2xl font-bold text-base-content">Email Logs</h1>
          <p class="text-sm text-base-content/60">
            Outbound mail delivery history. When Swoosh <code class="text-xs">:api_client</code>
            is disabled, deliveries are always recorded as sent (local / test mailbox).
            With an API client configured, status reflects the real provider result.
          </p>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Total</p>
            <p class="text-xl font-semibold">{@stats.total}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Sent</p>
            <p class="text-xl font-semibold text-success">{@stats.sent}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Failed</p>
            <p class="text-xl font-semibold text-error">{@stats.failed}</p>
          </div>
        </div>

        <div class="flex flex-wrap gap-2">
          <%= for {label, status} <- [{"All", "all"}, {"Sent", "sent"}, {"Failed", "failed"}] do %>
            <button
              type="button"
              phx-click="filter"
              phx-value-status={status}
              class={[
                "btn btn-sm",
                @filter == status && "btn-primary",
                @filter != status && "btn-ghost"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>

        <div class="overflow-x-auto rounded-box border border-base-300 bg-base-100 shadow-sm">
          <table class="table">
            <thead>
              <tr>
                <th>Subject</th>
                <th>To</th>
                <th>Type</th>
                <th>Mode</th>
                <th>Status</th>
                <th>Sent at</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={item <- @logs} id={"email-log-#{item.id}"} class="hover">
                <td class="max-w-xs truncate font-medium">{item.subject}</td>
                <td class="font-mono text-sm">{item.to_address}</td>
                <td>
                  <span class="badge badge-sm badge-outline">
                    {item.notif_type || "general"}
                  </span>
                </td>
                <td>
                  <span class={[
                    "badge badge-sm",
                    item.api_client_enabled && "badge-info",
                    !item.api_client_enabled && "badge-ghost"
                  ]}>
                    {mode_label(item.api_client_enabled)}
                  </span>
                </td>
                <td>
                  <span class={["badge badge-sm capitalize", status_badge(item.status)]}>
                    {item.status}
                  </span>
                </td>
                <td class="text-sm text-base-content/70">
                  {format_datetime(item.inserted_at)}
                </td>
                <td>
                  <div title="View" class="inline-flex">
                    <button
                      type="button"
                      phx-click="select"
                      phx-value-id={item.id}
                      class="btn btn-ghost btn-sm btn-square text-info hover:bg-info/10"
                      aria-label="View"
                    >
                      <.icon name="hero-eye" class="size-5" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr :if={@logs == []}>
                <td colspan="7" class="py-8 text-center text-base-content/50">
                  No email logs yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div
        :if={@selected}
        id="email-log-details-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-click="close"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-2xl rounded-2xl bg-base-100 p-6 shadow-2xl" phx-click="noop">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h3 class="text-lg font-bold">{@selected.subject}</h3>
              <p class="mt-1 text-sm text-base-content/60 font-mono">
                To {@selected.to_address}
              </p>
              <p :if={@selected.from_address} class="text-xs text-base-content/50">
                From {@selected.from_address}
              </p>
            </div>
            <div class="flex flex-wrap gap-1 justify-end">
              <span class={["badge badge-sm capitalize", status_badge(@selected.status)]}>
                {@selected.status}
              </span>
              <span class="badge badge-sm badge-outline">
                {mode_label(@selected.api_client_enabled)}
              </span>
            </div>
          </div>

          <div
            :if={@selected.error_message}
            class="mt-4 rounded-lg border border-error/30 bg-error/5 p-3 text-sm text-error"
          >
            {@selected.error_message}
          </div>

          <pre class="mt-4 max-h-80 overflow-auto whitespace-pre-wrap rounded-lg bg-base-200 p-4 text-sm text-base-content/80">{@selected.body || "(empty body)"}</pre>

          <p class="mt-3 text-xs text-base-content/50">
            {(@selected.notif_type || "general") <> " · "}
            {(@selected.adapter || "unknown adapter") <> " · "}
            {format_datetime(@selected.inserted_at)}
          </p>

          <div class="mt-4 flex flex-wrap justify-end gap-2">
            <button
              type="button"
              phx-click="delete"
              phx-value-id={@selected.id}
              data-confirm="Delete this email log?"
              class="btn btn-ghost btn-sm text-error"
            >
              Delete
            </button>
            <button type="button" phx-click="close" class="btn btn-sm">Close</button>
          </div>
        </div>
      </div>
    </Layouts.user>
    """
  end
end
