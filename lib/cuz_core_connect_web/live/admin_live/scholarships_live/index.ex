defmodule CuzCoreConnectWeb.Admin.Scholarships do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Scholarships
  alias CuzCoreConnect.Scholarships.Scholarship

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Scholarships",
       current_page: :scholarships,
       filter: "all",
       selected_id: nil,
       show_form: false,
       form: nil
     )
     |> load_scholarships()}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:filter, status) |> load_scholarships()}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_id, String.to_integer(id))}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, selected_id: nil, show_form: false, form: nil)}
  end

  def handle_event("new", _params, socket) do
    form =
      %Scholarship{}
      |> Scholarships.change_scholarship(%{status: "active", coverage: "full"})
      |> to_form()

    {:noreply, assign(socket, show_form: true, form: form, selected_id: nil)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    scholarship = Scholarships.get_scholarship!(id)
    form = scholarship |> Scholarships.change_scholarship() |> to_form()

    {:noreply, assign(socket, show_form: true, form: form, selected_id: nil)}
  end

  def handle_event("validate", %{"scholarship" => params}, socket) do
    form =
      socket.assigns.form.data
      |> Scholarships.change_scholarship(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"scholarship" => params}, socket) do
    result =
      case socket.assigns.form.data.id do
        nil -> Scholarships.create_scholarship(params)
        _id -> Scholarships.update_scholarship(socket.assigns.form.data, params)
      end

    case result do
      {:ok, _scholarship} ->
        {:noreply,
         socket
         |> put_flash(:info, "Scholarship saved.")
         |> assign(show_form: false, form: nil)
         |> load_scholarships()}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("activate", %{"id" => id}, socket) do
    scholarship = Scholarships.get_scholarship!(id)

    case Scholarships.update_scholarship(scholarship, %{status: "active"}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Scholarship activated.")
         |> load_scholarships()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not activate scholarship.")}
    end
  end

  def handle_event("deactivate", %{"id" => id}, socket) do
    scholarship = Scholarships.get_scholarship!(id)

    case Scholarships.update_scholarship(scholarship, %{status: "inactive"}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Scholarship deactivated.")
         |> load_scholarships()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not deactivate scholarship.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    scholarship = Scholarships.get_scholarship!(id)

    case Scholarships.delete_scholarship(scholarship) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Scholarship deleted.")
         |> assign(:selected_id, nil)
         |> load_scholarships()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete scholarship.")}
    end
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp load_scholarships(socket) do
    scholarships =
      case socket.assigns.filter do
        "all" -> Scholarships.list_scholarships()
        status -> Scholarships.list_scholarships_by_status(status)
      end

    socket
    |> assign(:scholarships, scholarships)
    |> assign(:stats, Scholarships.scholarship_stats())
  end

  defp status_badge("active"), do: "badge-success"
  defp status_badge("inactive"), do: "badge-ghost"
  defp status_badge(_), do: "badge-ghost"

  defp coverage_label("full"), do: "Full"
  defp coverage_label("partial"), do: "Partial"
  defp coverage_label("tuition_only"), do: "Tuition only"
  defp coverage_label("other"), do: "Other"
  defp coverage_label(other), do: other

  @impl true
  def render(assigns) do
    selected = Enum.find(assigns.scholarships, &(&1.id == assigns.selected_id))
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
            <h1 class="text-2xl font-bold text-base-content">Scholarships</h1>
            <p class="text-sm text-base-content/60">
              Maintain scholarships students can select during registration receipt upload.
            </p>
          </div>
          <button type="button" phx-click="new" class="btn btn-primary btn-sm gap-2">
            <.icon name="hero-plus" class="size-4" /> New scholarship
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Total</p>
            <p class="text-xl font-semibold">{@stats.total}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Active</p>
            <p class="text-xl font-semibold text-success">{@stats.active}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Inactive</p>
            <p class="text-xl font-semibold text-base-content/50">{@stats.inactive}</p>
          </div>
        </div>

        <div class="rounded-box border border-base-300 bg-base-100 shadow-sm">
          <div class="flex flex-wrap items-center gap-2 border-b border-base-300 p-4">
            <button
              type="button"
              phx-click="filter"
              phx-value-status="all"
              class={["btn btn-sm", @filter == "all" && "btn-active"]}
            >
              All
            </button>
            <button
              type="button"
              phx-click="filter"
              phx-value-status="active"
              class={["btn btn-sm", @filter == "active" && "btn-active"]}
            >
              Active
            </button>
            <button
              type="button"
              phx-click="filter"
              phx-value-status="inactive"
              class={["btn btn-sm", @filter == "inactive" && "btn-active"]}
            >
              Inactive
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr class="text-xs text-base-content/60">
                  <th>Name</th>
                  <th>Code</th>
                  <th>Sponsor</th>
                  <th>Coverage</th>
                  <th>Status</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={item <- @scholarships} id={"scholarship-#{item.id}"} class="hover">
                  <td class="font-medium">{item.name}</td>
                  <td class="font-mono text-xs">{item.code || "—"}</td>
                  <td>{item.sponsor || "—"}</td>
                  <td>{coverage_label(item.coverage)}</td>
                  <td>
                    <span class={["badge badge-sm capitalize", status_badge(item.status)]}>
                      {item.status}
                    </span>
                  </td>
                  <td>
                    <div class="flex justify-end gap-1">
                      <button
                        type="button"
                        phx-click="select"
                        phx-value-id={item.id}
                        class="btn btn-ghost btn-xs"
                        title="view"
                      >
                        <.icon name="hero-eye" class="size-4" />
                      </button>
                      <button
                        type="button"
                        phx-click="edit"
                        phx-value-id={item.id}
                        class="btn btn-ghost btn-xs"
                        title="Edit"
                      >
                        <.icon name="hero-pencil-square" class="size-4" />
                      </button>
                      <button
                        :if={item.status != "active"}
                        type="button"
                        phx-click="activate"
                        phx-value-id={item.id}
                        class="btn btn-ghost btn-xs text-success"
                      >
                        Activate
                      </button>
                      <button
                        :if={item.status == "active"}
                        type="button"
                        phx-click="deactivate"
                        phx-value-id={item.id}
                        class="btn btn-ghost btn-xs"
                      >
                        Deactivate
                      </button>
                      <button
                        type="button"
                        phx-click="delete"
                        phx-value-id={item.id}
                        data-confirm="Delete this scholarship?"
                        class="btn btn-ghost btn-xs text-error"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
                <tr :if={@scholarships == []}>
                  <td colspan="6" class="py-8 text-center text-base-content/50">
                    No scholarships yet. Create one for students to select during registration.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div
        :if={@selected}
        id="scholarship-details-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-click="close"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl" phx-click="noop">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h3 class="text-lg font-bold">{@selected.name}</h3>
              <p class="mt-1 text-sm text-base-content/60">
                {@selected.sponsor || "No sponsor"} · {coverage_label(@selected.coverage)}
              </p>
            </div>
            <span class={["badge badge-sm capitalize", status_badge(@selected.status)]}>
              {@selected.status}
            </span>
          </div>
          <p class="py-4 leading-relaxed text-base-content/80">
            {@selected.description || "No description provided."}
          </p>
          <p :if={@selected.code} class="text-xs text-base-content/50">
            Code: <span class="font-mono">{@selected.code}</span>
          </p>
          <div class="mt-4 flex justify-end">
            <button type="button" phx-click="close" class="btn">Close</button>
          </div>
        </div>
      </div>

      <div
        :if={@show_form && @form}
        id="scholarship-form-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl">
          <h3 class="mb-4 text-lg font-bold">
            {if @form.data.id, do: "Edit scholarship", else: "New scholarship"}
          </h3>
          <.form
            for={@form}
            id="scholarship-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <.input field={@form[:name]} type="text" label="Name" required />
            <.input field={@form[:code]} type="text" label="Code" />
            <.input field={@form[:sponsor]} type="text" label="Sponsor" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input
              field={@form[:coverage]}
              type="select"
              label="Coverage"
              options={[
                {"Full", "full"},
                {"Partial", "partial"},
                {"Tuition only", "tuition_only"},
                {"Other", "other"}
              ]}
            />
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[
                {"Active", "active"},
                {"Inactive", "inactive"}
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
end
