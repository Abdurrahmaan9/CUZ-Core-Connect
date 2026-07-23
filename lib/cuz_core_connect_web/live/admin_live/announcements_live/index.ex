defmodule CuzCoreConnectWeb.Admin.Announcements do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Communications
  alias CuzCoreConnect.Communications.Announcement

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Announcements",
       current_page: :announcements,
       filter: "all",
       selected_id: nil,
       show_form: false,
       form: nil
     )
     |> load_announcements()}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:filter, status) |> load_announcements()}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_id, String.to_integer(id))}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, selected_id: nil, show_form: false, form: nil)}
  end

  def handle_event("new", _params, socket) do
    form =
      %Announcement{}
      |> Communications.change_announcement(%{
        status: "draft",
        audience: "All Users",
        author: author_name(socket)
      })
      |> to_form()

    {:noreply, assign(socket, show_form: true, form: form, selected_id: nil)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    announcement = Communications.get_announcement!(id)
    form = announcement |> Communications.change_announcement() |> to_form()

    {:noreply, assign(socket, show_form: true, form: form, selected_id: nil)}
  end

  def handle_event("validate", %{"announcement" => params}, socket) do
    form =
      socket.assigns.form.data
      |> Communications.change_announcement(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"announcement" => params}, socket) do
    result =
      case socket.assigns.form.data.id do
        nil -> Communications.create_announcement(params)
        _id -> Communications.update_announcement(socket.assigns.form.data, params)
      end

    case result do
      {:ok, _announcement} ->
        {:noreply,
         socket
         |> put_flash(:info, "Announcement saved.")
         |> assign(show_form: false, form: nil)
         |> load_announcements()}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("publish", %{"id" => id}, socket) do
    announcement = Communications.get_announcement!(id)

    case Communications.update_announcement(announcement, %{status: "published"}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Announcement published.")
         |> load_announcements()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not publish announcement.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    announcement = Communications.get_announcement!(id)

    case Communications.delete_announcement(announcement) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Announcement deleted.")
         |> assign(:selected_id, nil)
         |> load_announcements()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete announcement.")}
    end
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp load_announcements(socket) do
    announcements =
      case socket.assigns.filter do
        "all" -> Communications.list_announcements()
        status -> Communications.list_announcements_by_status(status)
      end

    socket
    |> assign(:announcements, announcements)
    |> assign(:stats, Communications.announcement_stats())
  end

  defp author_name(socket) do
    case socket.assigns[:current_scope] do
      %{user: %{username: username}} when is_binary(username) and username != "" -> username
      %{user: %{email: email}} -> email
      _ -> "Admin"
    end
  end

  defp status_badge("published"), do: "badge-success"
  defp status_badge("scheduled"), do: "badge-info"
  defp status_badge("draft"), do: "badge-warning"
  defp status_badge(_), do: "badge-ghost"

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%d %b %Y, %H:%M")
  end

  @impl true
  def render(assigns) do
    selected = Enum.find(assigns.announcements, &(&1.id == assigns.selected_id))
    assigns = assign(assigns, :selected, selected)

    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <div class="space-y-6">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold text-base-content">Announcements</h1>
            <p class="text-sm text-base-content/60">
              Publish campus updates. Published items appear in the landing page marquee.
            </p>
          </div>
          <button type="button" phx-click="new" class="btn btn-primary btn-sm gap-2">
            <.icon name="hero-plus" class="size-4" /> New announcement
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.stat_card
            label="Total"
            value={@stats.total}
            icon="hero-megaphone"
            color="text-primary bg-primary/10"
          />
          <.stat_card
            label="Published"
            value={@stats.published}
            icon="hero-check-circle"
            color="text-success bg-success/10"
          />
          <.stat_card
            label="Scheduled"
            value={@stats.scheduled}
            icon="hero-clock"
            color="text-info bg-info/10"
          />
          <.stat_card
            label="Drafts"
            value={@stats.drafts}
            icon="hero-document-text"
            color="text-warning bg-warning/10"
          />
        </div>

        <div class="flex flex-wrap gap-2">
          <%= for {label, status} <- [{"All", "all"}, {"Published", "published"}, {"Scheduled", "scheduled"}, {"Drafts", "draft"}] do %>
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
                <th>Title</th>
                <th>Audience</th>
                <th>Author</th>
                <th>Status</th>
                <th>Published</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={item <- @announcements} id={"announcement-#{item.id}"} class="hover">
                <td class="max-w-xs truncate font-medium">{item.title}</td>
                <td>{item.audience}</td>
                <td>{item.author}</td>
                <td>
                  <span class={["badge badge-sm capitalize", status_badge(item.status)]}>
                    {item.status}
                  </span>
                </td>
                <td class="text-sm text-base-content/70">{format_datetime(item.published_at)}</td>
                <td>
                  <div class="flex justify-end gap-1">
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
                    <button
                      type="button"
                      phx-click="edit"
                      phx-value-id={item.id}
                      class="btn btn-ghost btn-xs"
                    >
                      Edit
                    </button>
                    <button
                      :if={item.status != "published"}
                      type="button"
                      phx-click="publish"
                      phx-value-id={item.id}
                      class="btn btn-ghost btn-xs text-success"
                    >
                      Publish
                    </button>
                    <button
                      type="button"
                      phx-click="delete"
                      phx-value-id={item.id}
                      data-confirm="Delete this announcement?"
                      class="btn btn-ghost btn-xs text-error"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
              <tr :if={@announcements == []}>
                <td colspan="6" class="py-8 text-center text-base-content/50">
                  No announcements yet. Create one to show on the landing page marquee.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div
        :if={@selected}
        id="announcement-details-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-click="close"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl" phx-click="noop">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h3 class="text-lg font-bold">{@selected.title}</h3>
              <p class="mt-1 text-sm text-base-content/60">
                {@selected.author} · {@selected.audience}
              </p>
            </div>
            <span class={["badge badge-sm capitalize", status_badge(@selected.status)]}>
              {@selected.status}
            </span>
          </div>
          <p class="py-4 leading-relaxed text-base-content/80">{@selected.body}</p>
          <div class="flex justify-between text-xs text-base-content/50">
            <span>Published: {format_datetime(@selected.published_at)}</span>
          </div>
          <div class="mt-4 flex justify-end">
            <button type="button" phx-click="close" class="btn">Close</button>
          </div>
        </div>
      </div>

      <div
        :if={@show_form && @form}
        id="announcement-form-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl">
          <h3 class="mb-4 text-lg font-bold">
            {if @form.data.id, do: "Edit announcement", else: "New announcement"}
          </h3>
          <.form
            for={@form}
            id="announcement-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <.input field={@form[:title]} type="text" label="Title" required />
            <.input field={@form[:body]} type="textarea" label="Body" required />
            <.input field={@form[:audience]} type="text" label="Audience" />
            <.input field={@form[:author]} type="text" label="Author" />
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[
                {"Draft", "draft"},
                {"Published", "published"},
                {"Scheduled", "scheduled"}
              ]}
            />
            <div class="flex justify-end gap-2 pt-2">
              <button type="button" phx-click="close" class="btn btn-ghost">Cancel</button>
              <button type="submit" class="btn btn-primary">Save</button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.user>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
      <div class="flex items-center gap-3">
        <div class={["rounded-full p-3", @color]}>
          <.icon name={@icon} class="size-5" />
        </div>
        <div>
          <p class="text-sm text-base-content/60">{@label}</p>
          <p class="text-xl font-semibold">{@value}</p>
        </div>
      </div>
    </div>
    """
  end
end
