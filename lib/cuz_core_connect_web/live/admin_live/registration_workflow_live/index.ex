defmodule CuzCoreConnectWeb.Admin.RegistrationWorkflow do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.WorkFlows
  alias CuzCoreConnect.Budgets
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
        memos: true,
        search_filter: ""
      )
      |> load_filtered_memo_flows()

    {:ok,
     socket
     |> assign(:page_title, "Registration Work Flows")
     |> assign(:current_page, :registration_workflows)
     |> assign(:show_registration_formcomponent, false)
     |> assign(:registration_workflow, :nil)
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

  def load_filtered_memo_flows(socket) do
    # data = WorkFlows.list_peginated_memo_flows(Pagination.create_table_params(socket, socket.assigns.params), %{search_filter: socket.assigns.search_filter})

    socket
    |> assign(:memo_flows, [])
    |> assign(:memo_flows_pagenations, %{})
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    socket =
      socket
      |> Pagination.filter_composer(params)
      |> Pagination.push_filters(~p"/admin/student")

    {:noreply, socket}
  end


  def handle_event("new_memo_flow", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_registration_formcomponent, true)
     |> assign(:registration_workflow, %CuzCoreConnect.Registrations.RegistrationWorkflow{})
     |> assign(:form_mode, :new)
    }
  end

  def handle_event("edit_memo_flow", params, socket) do
    {:noreply,
     push_navigate(socket,
       to:
         ~p"/administration/work_flows/memo/#{params["id"]}/edit?redirect=#{~p"/administration/work_flows/memos"}"
     )}
  end

  def handle_event("duplicate_memo_flow", %{"id" => id} = _params, socket) do
    memo_flow = WorkFlows.get_memo_flows_by_id(id)

    flow_steps =
      memo_flow.flow
      |> Enum.map(fn step ->
        %{
          "id" => step.id,
          "step_no" => step.step_no,
          "description" => step.description,
          "department_type" => step.department_type,
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
              "department_type" => "initiator",
              "required_titles" => [],
              "department_id" => nil
            }
          ]

        steps ->
          steps
      end

    duplicated_attrs =
      memo_flow
      |> Map.from_struct()
      |> Map.drop([:id, :inserted_at, :updated_at])
      |> Map.put(:name, memo_flow.name <> " (Copy)")
      |> Map.put(:flow, flow_steps)
      |> Map.put(:is_active, "true")

    case WorkFlows.create_memo_flow(duplicated_attrs) do
      {:ok, _new_memo} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memo Flow duplicated successfully.")
         |> push_navigate(to: ~p"/administration/work_flows/memos")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to duplicate memo flow.")
         |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete_memo_flow", %{"id" => id} = _params, socket) do
    with memo_flow <- WorkFlows.get_memo_flows_by_id(id),
         {:ok, _new_memo} <- WorkFlows.update_memo_flow(memo_flow, %{is_deleted: true}) do
      {:noreply,
       socket
       |> put_flash(:info, "Memo flow deleted successfully")
       |> push_navigate(to: ~p"/administration/work_flows/memos")}
    else
      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete memo flow.")
         |> assign(:changeset, changeset)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete memo flow. Memo Flow unrecognized")}
    end
  end

  def render(assigns) do
    ~H"""
      <div class="p-4">
      <div class="bg-gradient-to-r from-indigo-600 to-purple-700 rounded-xl p-6 mb-8 shadow-lg">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-center mb-4 sm:mb-0">
            <div class="w-12 h-12 bg-white bg-opacity-20 rounded-lg flex items-center justify-center mr-4">
              <i class="fas fa-project-diagram text-white text-xl"></i>
            </div>
            <div>
              <h1 class="text-2xl font-bold text-white">Workflow Management</h1>
              <p class="text-indigo-100 text-sm">Manage Approval Work Flows From Here</p>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden mt-6">
          <div class="border-b border-gray-200 overflow-x-auto whitespace-nowrap">
            <nav class="inline-flex mb-px">
              <.link
                href="/administration/work_flows"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @all_flows, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                All Work Flows
              </.link>
              <.link
                href="/administration/work_flows/memos"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @memos, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Memorundam Flows
              </.link>
              <.link
                href="/administration/work_flows/hr"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @hr, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Human Resource Flows
              </.link>
              <.link
                href="/administration/work_flows/finance"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @finance, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Finance Flows
              </.link>

              <.link
                href="/administration/work_flows/procurement"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @procurement, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Procurement Flows
              </.link>

              <.link
                href="/administration/work_flows/advert"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @advert, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Advert Flows
              </.link>

              <.link
                href="/administration/work_flows/recovery"
                class={"py-4 px-6 text-center border-b-2 font-medium text-sm #{if @recovery, do: "border-indigo-500 text-indigo-600", else: "border-transparent hover:text-gray-700 hover:border-gray-300"}"}
              >
                Recovery Flows
              </.link>
            </nav>
          </div>
        </div>
      </div>

      <%= if @all_flows do %>
        <div class="bg-white rounded-t-lg shadow-md overflow-hidden mb-1">
          <div class="p-4 border-b border-gray-200 flex justify-between items-center">
            <h3 class="text-lg font-medium text-gray-900">
              <i class="fas fa-list-ul mr-2 text-indigo-500"></i> All System Document Flows
            </h3>
          </div>
        </div>
        <div class="bg-white shadow-md overflow-hidden mb-6">
          <div class="p-6">
            <div class="overflow-x-auto">
              <CuzCoreConnectWeb.Datatable.Table.table id="flows" rows={@flows}>
                <:col :let={flow} label="Flow Name">
                  <div class="flex items-center">
                    <div class={"flex-shrink-0 h-10 w-10 bg-#{flow.icon_color}-100 rounded-full flex items-center justify-center"}>
                      <i class={"fas #{flow.icon} text-#{flow.icon_color}-600"}></i>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">{flow.name}</div>
                      <div class="text-sm text-gray-500">{flow.description}</div>
                    </div>
                  </div>
                </:col>

                <:col :let={flow} label="Category">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-#{flow.icon_color}-100 text-#{flow.icon_color}-800"}>
                    {flow.category}
                  </span>
                </:col>

                <:col :let={flow} label="Steps">
                  {flow.steps} steps
                </:col>

                <:col :let={flow} label="Last Updated">
                  {Timex.format!(flow.updated_at, "{M}/{D}/{YYYY}")}
                </:col>

                <:col :let={flow} label="Status">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if flow.is_active, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"}"}>
                    {if flow.is_active, do: "Active", else: "Inactive"}
                  </span>
                </:col>

                <:action :let={flow}>
                  <.link href={flow.view}>
                    <.button variant={:view}></.button>
                  </.link>
                </:action>
              </CuzCoreConnectWeb.Datatable.Table.table>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @memos do %>
        <div id="memos">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-file-alt mr-2 text-indigo-500"></i> Memorandum Flows
              </h3>

              <.form for={%{}} phx-change="seach_memo_flow">
                <.input
                  id="memo-flow-filter-search"
                  name="search_filter[search_term]"
                  value={@search_filter}
                  placeholder="Type here to search Memo flow..."
                />
              </.form>

              <.button
                phx-click="new_memo_flow"
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center"
              >
                <i class="fas fa-plus mr-2"></i> Add New Flow
              </.button>
            </div>
            <div class="p-6">
              <%= if !Enum.empty?(@memo_flows) do %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-4">
                  <%= for flow <- @memo_flows do %>
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
                            <.button variant={:edit} phx-click="edit_memo_flow" phx-value-id={flow.id}>
                            </.button>
                            <.button
                              variant={:view}
                              phx-click={JS.toggle(to: "#flow-details-#{flow.id}")}
                            >
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
                                  Step {index + 1}: {String.capitalize(step.department_type)}
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
                              variant={:duplicate}
                              phx-click="duplicate_memo_flow"
                              phx-value-id={flow.id}
                            >
                            </.button>

                            <.confirmation_modal
                              id="confirmation-modal-delete-memo-flow"
                              show={false}
                              title="Confirm Deletion"
                              message={"Are you sure you want to delete this Memo Flow?\nFlow Title: #{flow.name}"}
                              icon="warning"
                              on_cancel="close_modal"
                              on_confirm="delete_memo_flow"
                              on_confirm_params={%{id: flow.id}}
                            />

                            <.button
                              variant={:delete}
                              phx-click={show("confirmation-modal-delete-memo-flow")}
                              class="mt-4 text-sm text-gray-500"
                            >
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
                    pagination_data={@memo_flows_pagenations}
                  />
              <% else %>
                <!-- Empty State -->
                <div class="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                  <i class="fas fa-file-alt text-gray-400 text-4xl mb-3"></i>
                  <h3 class="text-lg font-medium text-gray-900 mb-1">No memorandum flows found</h3>
                  <p class="text-sm text-gray-500 mb-4">
                    Try adjusting the seach filter or Create your first memorandum workflow to get started
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @hr do %>
        <div id="procurement">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-document mr-2 text-indigo-500"></i> Human Flows
              </h3>
              <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center">
                <i class="fas fa-recycle mr-2"></i> Refresh
              </button>
            </div>
            <div class="p-6">
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-4">
                  <div class="relative">
                    <select class="appearance-none bg-white border border-gray-300 rounded-md pl-3 pr-8 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                      <option>All Status</option>
                      <option>Active</option>
                      <option>Inactive</option>
                      <option>Draft</option>
                    </select>
                    <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
                      <i class="fas fa-chevron-down text-xs"></i>
                    </div>
                  </div>
                  <div class="relative">
                    <input
                      type="text"
                      placeholder="Search flows..."
                      class="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <i class="fas fa-search text-gray-400"></i>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-4">
                <%= if !Enum.empty?(@hr_flows) do %>
                  <!-- HR Flow Item -->
                  <%= for flow <- @hr_flows do %>
                    <div class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
                      <div class="p-4 flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                          <div class="flex-shrink-0 h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                            <i class="fas fa-user-plus text-green-600"></i>
                          </div>
                          <div>
                            <h4 class="text-sm font-medium text-gray-900">
                              {String.capitalize(flow.name)}
                            </h4>
                            <%!-- <p class="text-sm text-gray-500">8-step process for new employees</p> --%>
                          </div>
                        </div>
                        <div class="flex items-center space-x-4">
                          <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                            Active
                          </span>
                          <div class="flex space-x-2">
                            <.link
                              patch={~p"/administration/work_flows/procurement/#{flow.id}/show/edit"}
                              phx-click={JS.push_focus()}
                            >
                              <.button variant={:edit}></.button>
                            </.link>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% else %>
                  <!-- Empty State -->
                  <div class="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
                    <i class="fas fa-users text-gray-400 text-4xl mb-3"></i>
                    <h3 class="text-lg font-medium text-gray-900 mb-1">No HR workflows yet</h3>
                    <p class="text-sm text-gray-500 mb-4">
                      Create your first HR workflow to get started
                    </p>
                    <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center mx-auto">
                      <i class="fas fa-plus mr-2"></i> Add Flow
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @finance do %>
        <div id="finance">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-money-bill-wave mr-2 text-indigo-500"></i> Finance Flows
              </h3>

              <%= if @finance_flow_payment do %>
                <.link href={"/administration/work_flows/finance/payments/new?redirect=#{~p"/administration/work_flows/finance"}"}>
                  <.button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center mx-auto">
                    <i class="fas fa-plus mr-2"></i> Create Payments Flow (PettyCash/Imprest)
                  </.button>
                </.link>
              <% end %>
            </div>

            <%= if Enum.empty?(@finance_flow) do %>
              <div class="p-6">
                <div class="flex flex-col items-center justify-center py-12">
                  <div class="bg-indigo-100 p-4 rounded-full mb-4">
                    <i class="fas fa-file-invoice-dollar text-indigo-600 text-3xl"></i>
                  </div>
                  <h3 class="text-xl font-medium text-gray-900 mb-2">No finance workflows yet</h3>
                  <p class="text-gray-500 mb-6 max-w-md text-center">
                    Finance workflows help automate expense approvals, invoice processing, and budget requests.
                  </p>
                </div>
              </div>
            <% else %>
              <div class="p-4">
                <div class="flow-steps space-y-4">
                  <% @finance_flow %>
                  <%= for flow <- @finance_flow do %>
                    <div
                      class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition"
                      id={"flow-card-#{flow.id}"}
                    >
                      <!-- Compact Card View -->
                      <div class="p-5 flow-summary">
                        <div class="flex items-center mb-4">
                          <div class={"flex-shrink-0 h-10 w-10 #{if flow.is_active, do: "bg-green-100 text-green-600", else: "bg-gray-100 text-gray-600"} rounded-full flex items-center justify-center"}>
                            <i class="fas fa-money-bill-wave"></i>
                          </div>
                          <div class="ml-4">
                            <h3 class="text-lg font-medium text-gray-900">{flow.name}</h3>
                            <p class="text-sm text-gray-500">
                              {length(flow.flow)} stage process
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
                            <.button
                              variant={:view}
                              phx-click={JS.toggle(to: "#flow-details-#{flow.id}")}
                            >
                            </.button>
                            <.button
                              variant={:edit}
                              phx-click="edit_finance_flow"
                              phx-value-id={flow.id}
                            >
                            </.button>
                          </div>
                        </div>
                      </div>

                      <div
                        id={"flow-details-#{flow.id}"}
                        class="hidden flow-details p-5 border-t border-gray-200"
                      >
                        <h4 class="font-medium text-gray-700 mb-4">Approval Flow Stages</h4>

                        <div class="space-y-4">
                          <%= for {step, index} <- Enum.with_index(flow.flow) do %>
                            <div class="flow-step bg-gray-50 p-4 rounded-lg border">
                              <div class="flex justify-between items-start mb-2">
                                <h5 class="font-medium text-gray-800">
                                  Stage {index + 1}: {String.capitalize(
                                    step.stage_name || step.department_type
                                  )}
                                </h5>
                                <span class="text-xs text-gray-500">
                                  {length(step.required_titles)} possible approver(s)
                                </span>
                              </div>

                              <%= if step.description && step.description != "" do %>
                                <p class="text-sm text-gray-600 mb-3">
                                  discription: {step.description |> String.capitalize()}
                                </p>
                              <% end %>

                              <div class="mb-3">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                                  {step.department_type |> String.replace("_", " ")}
                                </span>
                              </div>

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

                        <div class="mt-4 text-sm text-gray-500">
                          <p>
                            Created: {if(is_nil(flow.inserted_at),
                              do: "N/A",
                              else: Calendar.strftime(flow.inserted_at, "%H:%M %B %d, %Y")
                            )}
                          </p>
                          <p>
                            Last updated: {if(is_nil(flow.updated_at),
                              do: "N/A",
                              else: Calendar.strftime(flow.updated_at, "%H:%M %B %d, %Y")
                            )}
                          </p>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @procurement do %>
        <div id="procurement">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-document mr-2 text-indigo-500"></i> Procurement Flows
              </h3>
              <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center">
                <i class="fas fa-recycle mr-2"></i> Refresh
              </button>
            </div>
            <div class="p-6">
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-4">
                  <div class="relative">
                    <select class="appearance-none bg-white border border-gray-300 rounded-md pl-3 pr-8 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                      <option>All Status</option>
                      <option>Active</option>
                      <option>Inactive</option>
                      <option>Draft</option>
                    </select>
                    <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
                      <i class="fas fa-chevron-down text-xs"></i>
                    </div>
                  </div>
                  <div class="relative">
                    <input
                      type="text"
                      placeholder="Search flows..."
                      class="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <i class="fas fa-search text-gray-400"></i>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-4">
                <%= if !Enum.empty?(@procurement_flows) do %>
                  <!-- HR Flow Item -->
                  <%= for flow <- @procurement_flows do %>
                    <div class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
                      <div class="p-4 flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                          <div class="flex-shrink-0 h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                            <i class="fas fa-user-plus text-green-600"></i>
                          </div>
                          <div>
                            <h4 class="text-sm font-medium text-gray-900">
                              {String.capitalize(flow.name)}
                            </h4>
                            <%!-- <p class="text-sm text-gray-500">8-step process for new employees</p> --%>
                          </div>
                        </div>
                        <div class="flex items-center space-x-4">
                          <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                            Active
                          </span>
                          <div class="flex space-x-2">
                            <.link
                              patch={~p"/administration/work_flows/procurement/#{flow.id}/show/edit"}
                              phx-click={JS.push_focus()}
                            >
                              <.button variant={:edit}></.button>
                            </.link>
                            <%!-- <button class="text-gray-600 hover:text-gray-900">
                                <i class="fas fa-eye"></i>
                              </button> --%>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% else %>
                  <!-- Empty State -->
                  <div class="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
                    <i class="fas fa-users text-gray-400 text-4xl mb-3"></i>
                    <h3 class="text-lg font-medium text-gray-900 mb-1">
                      No Procurement workflows yet
                    </h3>
                    <p class="text-sm text-gray-500 mb-4">
                      Create your first Procurment workflow to get started
                    </p>
                    <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center mx-auto">
                      <i class="fas fa-plus mr-2"></i> Add Flow
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @advert do %>
        <div id="advert">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-document mr-2 text-indigo-500"></i> Advert Flows
              </h3>
              <%!-- <.link patch={~p"/administration/work_flows/advert/#{flow.id}/show/edit"} phx-click={JS.push_focus()}> --%>

              <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center">
                <i class="fas fa-recycle mr-2"></i> Refresh
              </button>
              <%!-- </.link> --%>
            </div>
            <div class="p-6">
              <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-4">
                  <div class="relative">
                    <select class="appearance-none bg-white border border-gray-300 rounded-md pl-3 pr-8 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                      <option>All Status</option>
                      <option>Active</option>
                      <option>Inactive</option>
                      <option>Draft</option>
                    </select>
                    <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
                      <i class="fas fa-chevron-down text-xs"></i>
                    </div>
                  </div>
                  <div class="relative">
                    <input
                      type="text"
                      placeholder="Search flows..."
                      class="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <i class="fas fa-search text-gray-400"></i>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-4">
                <%= if !Enum.empty?(@advert_flows) do %>
                  <!-- HR Flow Item -->
                  <%= for flow <- @advert_flows do %>
                    <div class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
                      <div class="p-4 flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                          <div class="flex-shrink-0 h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                            <i class="fas fa-user-plus text-green-600"></i>
                          </div>
                          <div>
                            <h4 class="text-sm font-medium text-gray-900">
                              {String.capitalize(flow.name)}
                            </h4>
                            <%!-- <p class="text-sm text-gray-500">8-step process for new employees</p> --%>
                          </div>
                        </div>
                        <div class="flex items-center space-x-4">
                          <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                            Active
                          </span>
                          <div class="flex space-x-2">
                            <.link
                              patch={~p"/administration/work_flows/advert/#{flow.id}/show/edit"}
                              phx-click={JS.push_focus()}
                            >
                              <.button variant={:edit}></.button>
                            </.link>
                            <%!-- <button class="text-gray-600 hover:text-gray-900">
                                <i class="fas fa-eye"></i>
                              </button> --%>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% else %>
                  <!-- Empty State -->
                  <div class="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
                    <i class="fas fa-users text-gray-400 text-4xl mb-3"></i>
                    <h3 class="text-lg font-medium text-gray-900 mb-1">No HR workflows yet</h3>
                    <p class="text-sm text-gray-500 mb-4">
                      Create your first HR workflow to get started
                    </p>
                    <button class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center mx-auto">
                      <i class="fas fa-plus mr-2"></i> Add Flow
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @recovery do %>
        <div id="recovery">
          <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
            <div class="p-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-medium text-gray-900">
                <i class="fas fa-file-alt mr-2 text-indigo-500"></i> Recovery Flows
              </h3>
              <.button
                phx-click="new_recovery_flow"
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center"
              >
                <i class="fas fa-plus mr-2"></i> Add New Flow
              </.button>
            </div>
            <div class="p-6">
              <%= if !Enum.empty?(@recovery_flows) do %>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <%= for flow <- @recovery_flows do %>
                    <div
                      class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition"
                      id={"flow-card-#{flow.id}"}
                      phx-hook="ExpandFlow"
                    >
                      <!-- Compact Card View -->
                      <div class="p-5 flow-summary">
                        <div class="flex items-center mb-4">
                          <div class={"flex-shrink-0 h-10 w-10 #{if flow.is_active, do: "bg-green-100 text-green-600", else: "bg-gray-100 text-gray-600"} rounded-full flex items-center justify-center"}>
                            <i class="fas fa-file-signature"></i>
                          </div>
                          <div class="ml-4">
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
                            <.button
                              variant={:edit}
                              phx-click="edit_recovery_flow"
                              phx-value-id={flow.id}
                            >
                            </.button>
                            <.button
                              variant={:view}
                              phx-click={JS.toggle(to: "#flow-details-#{flow.id}")}
                            >
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
                                  Step {index + 1}: {String.capitalize(step.department_type)}
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
                              variant={:duplicate}
                              phx-click="duplicate_recovery_flow"
                              phx-value-id={flow.id}
                            >
                            </.button>

                            <.confirmation_modal
                              id="confirmation-modal-delete-recovery-flow"
                              show={false}
                              title="Confirm Deletion"
                              message={"Are you sure you want to delete this Recovery Flow?\nFlow Title: #{flow.name}"}
                              icon="warning"
                              on_cancel="close_modal"
                              on_confirm="delete_recovery_flow"
                              on_confirm_params={%{id: flow.id}}
                            />

                            <.button
                              variant={:delete}
                              phx-click={show("confirmation-modal-delete-recovery-flow")}
                              class="mt-4 text-sm text-gray-500"
                            >
                            </.button>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <!-- Empty State -->
                <div class="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                  <i class="fas fa-file-alt text-gray-400 text-4xl mb-3"></i>
                  <h3 class="text-lg font-medium text-gray-900 mb-1">No loan recovery flows yet</h3>
                  <p class="text-sm text-gray-500 mb-4">
                    Create your first loan recovery workflow to get started
                  </p>
                  <.button
                    phx-click="new_recovery_flow"
                    class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 transition flex items-center mx-auto"
                  >
                    <i class="fas fa-plus mr-2"></i> Add Flow
                  </.button>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <.live_component
        :if={@show_registration_formcomponent}
        module={__MODULE__.FormComponent}
        id={"#{@registration_workflow.id}-registration-workflow"}
        form_mode={@form_mode}
        registration_workflow={@registration_workflow}
      />
    </div>

    """
  end
end
