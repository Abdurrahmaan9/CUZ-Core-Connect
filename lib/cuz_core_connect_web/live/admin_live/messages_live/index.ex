defmodule CuzCoreConnectWeb.Admin.Messages do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Communications

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Messages",
       current_page: :messages,
       filter: "all",
       selected_id: nil
     )
     |> load_messages()}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:filter, status) |> load_messages()}
  end

  def handle_event("select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    message = Communications.get_message!(id)

    socket =
      if message.status == "unread" do
        {:ok, message} = Communications.mark_message_read(message)

        socket
        |> assign(:selected_id, message.id)
        |> load_messages()
      else
        assign(socket, :selected_id, id)
      end

    {:noreply, socket}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :selected_id, nil)}
  end

  def handle_event("archive", %{"id" => id}, socket) do
    message = Communications.get_message!(id)

    case Communications.archive_message(message) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Message archived.")
         |> assign(:selected_id, nil)
         |> load_messages()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not archive message.")}
    end
  end

  def handle_event("toggle_landing", %{"id" => id}, socket) do
    message = Communications.get_message!(id)

    case Communications.update_message(message, %{show_on_landing: !message.show_on_landing}) do
      {:ok, _} ->
        {:noreply, load_messages(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update message.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    message = Communications.get_message!(id)

    case Communications.delete_message(message) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Message deleted.")
         |> assign(:selected_id, nil)
         |> load_messages()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete message.")}
    end
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp load_messages(socket) do
    messages =
      case socket.assigns.filter do
        "all" -> Communications.list_messages()
        status -> Communications.list_messages_by_status(status)
      end

    socket
    |> assign(:messages, messages)
    |> assign(:stats, Communications.message_stats())
  end

  defp status_badge("unread"), do: "badge-primary"
  defp status_badge("read"), do: "badge-ghost"
  defp status_badge("archived"), do: "badge-neutral"
  defp status_badge(_), do: "badge-ghost"

  defp priority_badge("high"), do: "badge-error"
  defp priority_badge("normal"), do: "badge-info"
  defp priority_badge("low"), do: "badge-ghost"
  defp priority_badge(_), do: "badge-ghost"

  defp source_label("contact"), do: "Contact form"
  defp source_label("registration"), do: "Registration"
  defp source_label("system"), do: "System"
  defp source_label(other), do: other

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y, %H:%M")
  defp format_datetime(_), do: "—"

  @impl true
  def render(assigns) do
    selected = Enum.find(assigns.messages, &(&1.id == assigns.selected_id))
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
          <h1 class="text-2xl font-bold text-base-content">Messages</h1>
          <p class="text-sm text-base-content/60">
            Inbox for landing-page contact messages and student registration notices.
          </p>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Total</p>
            <p class="text-xl font-semibold">{@stats.total}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Unread</p>
            <p class="text-xl font-semibold">{@stats.unread}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Read</p>
            <p class="text-xl font-semibold">{@stats.read}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Archived</p>
            <p class="text-xl font-semibold">{@stats.archived}</p>
          </div>
        </div>

        <div class="flex flex-wrap gap-2">
          <%= for {label, status} <- [{"All", "all"}, {"Unread", "unread"}, {"Read", "read"}, {"Archived", "archived"}] do %>
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
                <th>From</th>
                <th>Source</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Landing</th>
                <th>Received</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={item <- @messages}
                id={"message-#{item.id}"}
                class={["hover", item.status == "unread" && "font-semibold"]}
              >
                <td class="max-w-xs truncate">{item.subject}</td>
                <td>
                  <div class="flex flex-col font-normal">
                    <span>{item.name}</span>
                    <span class="text-xs text-base-content/50">{item.email}</span>
                  </div>
                </td>
                <td>
                  <span class="badge badge-sm badge-outline">{source_label(item.source)}</span>
                </td>
                <td>
                  <span class={["badge badge-sm capitalize", priority_badge(item.priority)]}>
                    {item.priority}
                  </span>
                </td>
                <td>
                  <span class={["badge badge-sm capitalize", status_badge(item.status)]}>
                    {item.status}
                  </span>
                </td>
                <td>
                  <span class={["badge badge-sm", item.show_on_landing && "badge-success", !item.show_on_landing && "badge-ghost"]}>
                    {if item.show_on_landing, do: "Shown", else: "Hidden"}
                  </span>
                </td>
                <td class="text-sm font-normal text-base-content/70">
                  {format_datetime(item.inserted_at)}
                </td>
                <td>
                  <div title="view" class="inline-flex">
                    <button
                      type="button"
                      phx-click="select"
                      phx-value-id={item.id}
                      class="btn btn-ghost btn-sm btn-square text-info"
                      aria-label="View"
                    >
                      <.icon name="hero-eye" class="size-5" />
                    </button>
                  </div>
                </td>
              </tr>
              <tr :if={@messages == []}>
                <td colspan="8" class="py-8 text-center font-normal text-base-content/50">
                  No messages yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div
        :if={@selected}
        id="message-details-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-click="close"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl" phx-click="noop">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h3 class="text-lg font-bold">{@selected.subject}</h3>
              <p class="mt-1 text-sm text-base-content/60">
                From {@selected.name}
                <span :if={@selected.email}> &lt;{@selected.email}&gt;</span>
              </p>
            </div>
            <div class="flex gap-1">
              <span class={["badge badge-sm capitalize", priority_badge(@selected.priority)]}>
                {@selected.priority}
              </span>
              <span class={["badge badge-sm capitalize", status_badge(@selected.status)]}>
                {@selected.status}
              </span>
            </div>
          </div>
          <p class="py-4 leading-relaxed text-base-content/80">{@selected.body}</p>
          <p class="text-xs text-base-content/50">
            {source_label(@selected.source)} · Received {format_datetime(@selected.inserted_at)}
          </p>
          <div class="mt-4 flex flex-wrap justify-end gap-2">
            <button
              type="button"
              phx-click="toggle_landing"
              phx-value-id={@selected.id}
              class="btn btn-ghost btn-sm"
            >
              {if @selected.show_on_landing, do: "Hide from landing", else: "Show on landing"}
            </button>
            <button
              :if={@selected.status != "archived"}
              type="button"
              phx-click="archive"
              phx-value-id={@selected.id}
              class="btn btn-ghost btn-sm"
            >
              Archive
            </button>
            <button
              type="button"
              phx-click="delete"
              phx-value-id={@selected.id}
              data-confirm="Delete this message?"
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
