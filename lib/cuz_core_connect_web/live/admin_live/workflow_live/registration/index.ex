defmodule CuzCoreConnectWeb.Admin.RegistrationWorkflow do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Workflows
  alias CuzCoreConnectWeb.{
    Pagination,
    PaginationComponent,
  }

  @filter_defaults %{
    search_filter: "",
    page: "",
    page_size: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        registrations: true,
        search_filter: ""
      )
      |> load_filtered_registration_flows()

    {:ok,
     socket
     |> assign(:page_title, "Registration Work Flows")
     |> assign(:current_page, :registration_workflows)
     |> assign(:show_registration_formcomponent, false)
     |> assign(:registration_workflow, :nil)
     |> assign(:all_flows_tab, true)
     |> assign(:registrations_tab, false)
     |> assign(:form_mode, nil)
     |> Pagination.assign_filters(@filter_defaults)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
      |> assign(:params, params)
      |> Pagination.filter_composer(params)
    }
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
  def handle_event("filter", %{"filters" => params}, socket) do
    socket =
      socket
      |> Pagination.filter_composer(params)
      |> Pagination.push_filters(~p"/admin/student")

    {:noreply, socket}
  end


  def handle_event("new_registration_flow", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_registration_formcomponent, true)
     |> assign(:registration_workflow, %CuzCoreConnect.Workflows.RegistrationWorkflow{})
     |> assign(:form_mode, :new)
    }
  end

  def handle_event("edit_registration_flow", params, socket) do
    {:noreply,
     push_navigate(socket,
       to:
         ~p"/admin/workflows/registration/#{params["id"]}/edit?redirect=#{~p"/admin/workflows/registration"}"
     )}
  end

  def handle_event("duplicate_registration_flow", %{"id" => id} = _params, socket) do
    registration_flow = Workflows.get_registration_flows_by_id(id)

    flow_steps =
      registration_flow.flow
      |> Enum.map(fn step ->
        %{
          "id" => step.id,
          "step_no" => step.step_no,
          "description" => step.description,
          "actionar_type" => step.actionar_type,
          "required_titles" => step.required_titles,
          "department_id" => step.department_id
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
              "department_id" => nil
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
      |> Map.put(:is_active, "true")

    case Workflows.create_registration_flow(duplicated_attrs) do
      {:ok, _new_registration} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memo Flow duplicated successfully.")
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
         {:ok, _new_registration} <- Workflows.update_registration_flow(registration_flow, %{is_deleted: true}) do
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
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <div id="registrations">
        <div class="bg-gray-50/20 rounded-lg shadow-md overflow-hidden mb-6">
          <div class="p-4 border-b border-gray-200 flex justify-between items-center">
            <h3 class="text-lg font-medium">
              <i class="fas fa-file-alt mr-2 text-indigo-500"></i> Registration Flows
            </h3>

            <.form for={%{}} phx-change="seach_registration_flow">
              <.input
                id="registration-flow-filter-search"
                name="search_filter[search_term]"
                value={@search_filter}
                placeholder="Type here to search Memo flow..."
              />
            </.form>

            <.button
              phx-click="new_registration_flow"
              class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center"
            >
              <i class="fas fa-plus mr-2"></i> Add New Flow
            </.button>
          </div>
          <div class="p-6">
            <%= if !Enum.empty?(@data) do %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-4">
                <%= for flow <- @data do %>
                  <div
                    class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition"
                    id={"flow-card-#{flow.id}"}
                    phx-hook="ExpandFlow"
                  >
                    <!-- Compact Card View -->
                    <div class="p-5 flow-summary">
                      <div class="flex items-center mb-4">
                        <div>
                          <h3 class="text-lg font-medium text-gray-900">{flow.name}</h3>
                          <p class="text-sm text-gray-500">
                            {length(flow.flow)} step process
                            <%= if flow.description do %>
                              • {flow.description}
                            <% end %>
                          </p>
                        </div>
                      </div>
                      <div class="flex justify-between items-center mt-6">
                        <span class={"px-2 py-1 text-xs font-semibold rounded-full #{if flow.is_active, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"}"}>
                          {if flow.is_active, do: "Active", else: "Inactive"}
                        </span>
                        <div class="flex space-x-2">
                          <.button phx-click="edit_registration_flow" phx-value-id={flow.id}>
                            edit
                          </.button>
                          <.button
                            phx-click={JS.toggle(to: "#flow-details-#{flow.id}")}
                          >
                            view
                          </.button>
                        </div>
                      </div>
                    </div>

                    <div
                      id={"flow-details-#{flow.id}"}
                      class="hidden flow-details p-5 border-t border-gray-200"
                    >
                      <h4 class="font-medium text-gray-700 mb-4">Approval Flow</h4>

                      <div class="space-y-4">
                        <%= for {step, index} <- Enum.with_index(flow.flow) do %>
                          <div class="flow-step bg-gray-50 p-4 rounded-lg border">
                            <div class="flex justify-between items-start mb-2">
                              <h5 class="font-medium text-gray-800">
                                Step {index + 1}: {String.capitalize(step.actionar_type)}
                              </h5>
                              <span class="text-xs text-gray-500">
                                {length(step.required_titles)} required approver(s)
                              </span>
                            </div>

                            <p class="text-sm text-gray-600 mb-3">{step.description}</p>

                            <div class="flex flex-wrap gap-2">
                              <%= for title <- step.required_titles do %>
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                  {title}
                                </span>
                              <% end %>
                            </div>
                          </div>
                        <% end %>
                      </div>

                      <div class="flex justify-between">
                        <div class="mt-4 text-sm text-gray-500">
                          <p>Created: {Calendar.strftime(flow.inserted_at, "%H:%M %B %d, %Y")}</p>
                          <p>Last updated: {Calendar.strftime(flow.updated_at, "%H:%M %B %d, %Y")}</p>
                        </div>
                        <div class="mt-4 text-sm text-gray-500">
                          <.button
                            phx-click="duplicate_registration_flow"
                            phx-value-id={flow.id}
                          >
                            duplicate
                          </.button>

                          <.confirmation_modal
                            id="confirmation-modal-delete-registration-flow"
                            show={false}
                            title="Confirm Deletion"
                            message={"Are you sure you want to delete this Memo Flow?\nFlow Title: #{flow.name}"}
                            icon="warning"
                            on_cancel={
                              JS.exec(JS.push("close_set_default_modal"), "phx-remove",
                                to: "#confirmation-delete-key-#{flow.id}-modal"
                              )
                            }
                            on_confirm="delete_registration_flow"
                            on_confirm_params={%{id: flow.id}}
                          />

                          <.button
                            phx-click={show("confirmation-modal-delete-registration-flow")}
                            class="mt-4 text-sm text-gray-500"
                          >
                            delete
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
              <!-- Empty State -->
              <div class="border-2 border-dashed border-secondary rounded-lg p-6 text-center">
                <i class="fas fa-file-alt text-base-content text-4xl mb-3"></i>
                <h3 class="text-lg font-medium mb-1">No registration flows found</h3>
                <p class="text-sm text-base-content mb-4">
                  Try adjusting the seach filter or Create your first registration workflow to get started
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
    </Layouts.admin>
    """
  end
end
