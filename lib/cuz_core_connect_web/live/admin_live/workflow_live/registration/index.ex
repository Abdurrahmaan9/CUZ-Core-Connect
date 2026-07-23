defmodule CuzCoreConnectWeb.Admin.RegistrationWorkflow do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Workflows
  alias CuzCoreConnect.Registrations
  alias CuzCoreConnect.Workflows.RegistrationWorkflow

  alias CuzCoreConnectWeb.Datatable.{
    Pagination,
    PaginationComponent
  }

  @filter_defaults %{
    search_filter: "",
    page: "",
    page_size: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Registration Work Flows")
     |> assign(:current_page, :registration_workflows)
     |> assign(:show_registration_formcomponent, false)
     |> assign(:registration_workflow, nil)
     |> assign(:all_flows_tab, true)
     |> assign(:registrations_tab, false)
     |> assign(:form_mode, nil)
     |> assign(:confirm_switch_flow, nil)
     |> Pagination.assign_filters(@filter_defaults)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> Pagination.filter_composer(params)
     |> load_filtered_registration_flows()}
  end

  def load_filtered_registration_flows(socket) do
    data =
      Workflows.list_peginated_registration_flows(Pagination.fetch_current_filters(socket))

    socket
    |> assign(:data, data.entries)
    |> assign(:pagination_data, data |> Map.delete(:entries))
  end

  @impl true
  def handle_info({__MODULE__.FormComponent, {key, msg}}, socket) do
    socket =
      case key do
        :error ->
          socket
          |> put_flash(:error, msg)

        :success ->
          socket
          |> put_flash(:info, msg)

        _ ->
          socket
          |> put_flash(:info, msg)
      end

    {:noreply,
     socket
     |> assign(:show_registration_formcomponent, false)
     |> assign(:registration_workflow, nil)
     |> assign(:form_mode, nil)
     |> load_filtered_registration_flows()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    socket =
      socket
      |> Pagination.filter_composer(params)
      |> Pagination.push_filters(~p"/admin/workflows/registration")

    {:noreply, socket}
  end

  def handle_event("new_registration_flow", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_registration_formcomponent, true)
     |> assign(:registration_workflow, %RegistrationWorkflow{flow: []})
     |> assign(:form_mode, :new)}
  end

  def handle_event("edit_registration_flow", %{"id" => id}, socket) do
    registration_flow =
      Workflows.get_registration_flows_by_id(id)

    {:noreply,
     socket
     |> assign(:show_registration_formcomponent, true)
     |> assign(:registration_workflow, registration_flow)
     |> assign(:form_mode, :edit)}
  end

  def handle_event("duplicate_registration_flow", %{"id" => id} = _params, socket) do
    registration_flow =
      Workflows.get_registration_flows_by_id(id)

    flow_steps =
      registration_flow.flow
      |> Enum.map(fn step ->
        %{
          "step_no" => step.step_no,
          "description" => step.description,
          "actionar_type" => step.actionar_type,
          "required_titles" => step.required_titles,
          "role_key" => step.role_key,
          "actioner_id" => step.actioner_id
        }
      end)
      |> case do
        [] ->
          [
            %{
              "step_no" => 1,
              "description" => "",
              "actionar_type" => "initiator",
              "required_titles" => [],
              "role_key" => nil,
              "actioner_id" => nil
            }
          ]

        steps ->
          steps
      end

    duplicated_attrs =
      registration_flow
      |> Map.from_struct()
      |> Map.drop([:id, :inserted_at, :updated_at])
      |> Map.put(:name, registration_flow.name <> " (Copy)")
      |> Map.put(:flow, flow_steps)
      |> Map.put(:is_active, false)

    case Workflows.create_registration_flow(duplicated_attrs) do
      {:ok, _new_registration} ->
        {:noreply,
         socket
         |> put_flash(:info, "Registration flow duplicated successfully.")
         |> push_navigate(to: ~p"/admin/workflows/registration")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to duplicate registration flow.")
         |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete_registration_flow", %{"id" => id} = _params, socket) do
    with registration_flow <- Workflows.get_registration_flows_by_id(id),
         {:ok, _new_registration} <-
           Workflows.update_registration_flow(registration_flow, %{
             deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
           }) do
      {:noreply,
       socket
       |> put_flash(:info, "Memo flow deleted successfully")
       |> push_navigate(to: ~p"/admin/workflows/registration")}
    else
      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete registration flow.")
         |> assign(:changeset, changeset)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete registration flow. Memo Flow unrecognized")}
    end
  end

  @impl true
  def handle_event("toggle_active_flow", %{"id" => id}, socket) do
    id = String.to_integer(id)
    current_active = Workflows.get_active_registration_flow()

    cond do
      current_active && current_active.id == id ->
        {:noreply,
         put_flash(
           socket,
           :info,
           "This workflow is already active. Activate a different workflow to switch."
         )}

      true ->
        pending_count =
          if current_active do
            Workflows.count_incomplete_registrations_by_workflow(current_active.id)
          else
            0
          end

        if pending_count > 0 do
          {:noreply,
           assign(socket, :confirm_switch_flow, %{
             new_id: id,
             old_id: current_active.id,
             old_name: current_active.name,
             pending_count: pending_count
           })}
        else
          do_activate_flow(socket, id)
        end
    end
  end

  def handle_event("set_active_flow", %{"id" => id}, socket) do
    handle_event("toggle_active_flow", %{"id" => id}, socket)
  end

  @impl true
  def handle_event("confirm_switch_restart", _params, socket) do
    %{new_id: new_id, old_id: old_id} = socket.assigns.confirm_switch_flow

    Registrations.migrate_pending_registrations_workflow(old_id, new_id)

    do_activate_flow(assign(socket, :confirm_switch_flow, nil), new_id)
  end

  @impl true
  def handle_event("confirm_switch_keep", _params, socket) do
    # Keep old registrations on old workflow; new submissions use the newly activated one.
    %{new_id: new_id} = socket.assigns.confirm_switch_flow
    do_activate_flow(assign(socket, :confirm_switch_flow, nil), new_id)
  end

  @impl true
  def handle_event("cancel_switch_flow", _params, socket) do
    {:noreply, assign(socket, :confirm_switch_flow, nil)}
  end

  defp do_activate_flow(socket, id) do
    case Workflows.set_active_registration_flow(id) do
      {:ok, workflow} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "\"#{workflow.name}\" is now the active registration workflow. New registrations will use it."
         )
         |> load_filtered_registration_flows()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Workflow not found.")}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Failed to activate workflow: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <div id="registrations" class="space-y-6">
        <div class="overflow-hidden rounded-box border border-base-300 bg-base-100 shadow-sm">
          <div class="flex flex-col gap-4 border-b border-base-300 p-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h3 class="flex items-center gap-2 text-lg font-semibold text-base-content">
                <.icon name="hero-arrow-path" class="size-5 text-primary" />
                Registration Flows
              </h3>
              <p class="mt-1 text-sm text-base-content/60">
                Configure and activate the approval workflow for student registrations.
              </p>
            </div>

            <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
              <.form for={%{}} phx-change="filter" id="registration-flow-filter" class="w-full sm:w-72">
                <.input
                  id="registration-flow-filter-search"
                  name="search_filter"
                  value={@search_filter}
                  placeholder="Search flows..."
                />
              </.form>

              <.button phx-click="new_registration_flow" class="btn btn-primary gap-2">
                <.icon name="hero-plus" class="size-4" /> Add New Flow
              </.button>
            </div>
          </div>

          <div class="p-4 sm:p-6">
            <%= if !Enum.empty?(@data) do %>
              <div class="mb-4 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
                <%= for flow <- @data do %>
                  <div
                    class={[
                      "overflow-hidden rounded-box border bg-base-100 shadow-sm transition hover:shadow-md",
                      flow.is_active && "border-success/50 ring-1 ring-success/30",
                      !flow.is_active && "border-base-300 hover:border-primary/30"
                    ]}
                    id={"flow-card-#{flow.id}"}
                  >
                    <div class="space-y-4 p-5">
                      <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
                          <h3 class="text-lg font-medium text-base-content">{flow.name}</h3>
                          <p class="mt-1 text-sm text-base-content/60">
                            {length(flow.flow)} step process
                            <%= if flow.description do %>
                              · {flow.description}
                            <% end %>
                          </p>
                        </div>

                        <label
                          class="flex cursor-pointer flex-col items-center gap-1"
                          title={
                            if(flow.is_active,
                              do: "Currently active — new registrations use this flow",
                              else: "Activate this flow for new registrations"
                            )
                          }
                        >
                          <input
                            type="checkbox"
                            class="toggle toggle-success toggle-sm"
                            checked={flow.is_active}
                            phx-click="toggle_active_flow"
                            phx-value-id={flow.id}
                          />
                          <span class={[
                            "text-[10px] font-semibold uppercase tracking-wide",
                            flow.is_active && "text-success",
                            !flow.is_active && "text-base-content/50"
                          ]}>
                            {if flow.is_active, do: "Active", else: "Off"}
                          </span>
                        </label>
                      </div>

                      <div class="flex items-center justify-between gap-3">
                        <span class={[
                          "badge badge-sm",
                          flow.is_active && "badge-success",
                          !flow.is_active && "badge-ghost"
                        ]}>
                          {if flow.is_active,
                            do: "Used by new registrations",
                            else: "Inactive"}
                        </span>
                        <.button
                          type="button"
                          phx-click={JS.toggle(to: "#flow-details-#{flow.id}")}
                          class="btn btn-ghost btn-xs"
                        >
                          View
                        </.button>
                      </div>
                    </div>

                    <div
                      id={"flow-details-#{flow.id}"}
                      class="hidden space-y-4 border-t border-base-300 bg-base-200/40 p-5"
                    >
                      <h4 class="font-medium text-base-content">Approval Flow</h4>

                      <div class="space-y-3">
                        <%= for {step, index} <- Enum.with_index(flow.flow) do %>
                          <div class="rounded-box border border-base-300 bg-base-100 p-4">
                            <div class="mb-2 flex items-start justify-between gap-3">
                              <h5 class="font-medium text-base-content">
                                Step {index + 1}: {String.capitalize(step.actionar_type)
                                |> String.replace("_", " ")}
                              </h5>
                              <span class="text-xs text-base-content/50">
                                <%!-- {length(step.required_titles || [])} required approver(s) --%>
                              </span>
                            </div>

                            <p class="mb-3 text-sm text-base-content/70">{step.description}</p>

                            <div class="flex flex-wrap gap-2">
                              <%= for title <- step.required_titles || [] do %>
                                <span class="badge badge-sm badge-outline badge-info">
                                  {title}
                                </span>
                              <% end %>
                              <span
                                :if={step.role_key}
                                class="badge badge-sm badge-outline badge-primary"
                              >
                                {step.role_key}
                              </span>
                            </div>
                          </div>
                        <% end %>
                      </div>

                      <div class="space-y-1 text-sm text-base-content/70">
                        <p>Created: {Calendar.strftime(flow.inserted_at, "%H:%M %B %d, %Y")}</p>
                        <p>Last updated: {Calendar.strftime(flow.updated_at, "%H:%M %B %d, %Y")}</p>
                      </div>

                      <div class="flex flex-wrap items-center justify-between gap-2">
                        <.button
                          :if={!flow.is_active}
                          phx-click="toggle_active_flow"
                          phx-value-id={flow.id}
                          class="btn btn-success btn-sm"
                        >
                          Set Active
                        </.button>
                        <span :if={flow.is_active} class="badge badge-success">
                          Active — new registrations
                        </span>

                        <div class="flex flex-wrap gap-2">
                          <.button
                            phx-click="edit_registration_flow"
                            phx-value-id={flow.id}
                            class="btn btn-ghost btn-sm"
                          >
                            Edit
                          </.button>
                          <.button
                            phx-click="duplicate_registration_flow"
                            phx-value-id={flow.id}
                            class="btn btn-ghost btn-sm"
                          >
                            Duplicate
                          </.button>
                          <.button
                            phx-click="delete_registration_flow"
                            phx-value-id={flow.id}
                            data-confirm={"Delete workflow \"#{flow.name}\"? This cannot be undone."}
                            class="btn btn-ghost btn-sm text-error"
                          >
                            Delete
                          </.button>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>

              <.live_component
                module={PaginationComponent}
                id="PaginationComponent"
                params={@params}
                pagination_data={@pagination_data}
              />
            <% else %>
              <div class="rounded-box border-2 border-dashed border-base-300 p-10 text-center">
                <.icon
                  name="hero-document-duplicate"
                  class="mx-auto mb-3 size-10 text-base-content/30"
                />
                <h3 class="text-lg font-medium text-base-content">No registration flows found</h3>
                <p class="mt-1 text-sm text-base-content/60">
                  Try adjusting the search filter or create your first registration workflow.
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <.live_component
        :if={@show_registration_formcomponent}
        module={__MODULE__.FormComponent}
        id={"#{@registration_workflow.id}-registration-workflow"}
        form_mode={@form_mode}
        registration_workflow={@registration_workflow}
      />

      <.modal
        :if={@confirm_switch_flow}
        id="confirm-switch-flow-modal"
        show
        on_cancel={JS.push("cancel_switch_flow")}
      >
        <:title>Active Workflow Has Pending Registrations</:title>

        <div class="space-y-4 p-4">
          <p class="text-sm text-base-content/80">
            There are <strong>{@confirm_switch_flow.pending_count}</strong>
            registration(s) still in progress using <strong>{@confirm_switch_flow.old_name}</strong>.
          </p>
          <p class="text-sm text-base-content/80">How should these be handled?</p>

          <div class="space-y-2">
            <div class="rounded-box border border-warning/40 bg-warning/10 p-3">
              <p class="text-sm font-medium text-warning">Continue with old workflow</p>
              <p class="mt-1 text-xs text-base-content/70">
                In-progress registrations keep using <em>{@confirm_switch_flow.old_name}</em>.
                New registrations will use the new workflow.
              </p>
            </div>
            <div class="rounded-box border border-info/40 bg-info/10 p-3">
              <p class="text-sm font-medium text-info">Restart with new workflow</p>
              <p class="mt-1 text-xs text-base-content/70">
                All pending registrations will be moved to the new workflow and restart from step 1.
              </p>
            </div>
          </div>
        </div>

        <:footer>
          <div class="flex flex-wrap justify-between gap-2">
            <.button phx-click="cancel_switch_flow" class="btn btn-ghost">
              Cancel
            </.button>
            <div class="flex flex-wrap gap-2">
              <.button phx-click="confirm_switch_keep" class="btn btn-warning">
                Keep Old for In-Progress
              </.button>
              <.button phx-click="confirm_switch_restart" class="btn btn-primary">
                Restart with New Flow
              </.button>
            </div>
          </div>
        </:footer>
      </.modal>
    </Layouts.user>
    """
  end
end
