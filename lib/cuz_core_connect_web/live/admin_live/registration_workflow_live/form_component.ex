defmodule CuzCoreConnectWeb.Admin.RegistrationWorkflow.FormComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Accounts

  alias CuzCoreConnect.Registration
  alias CuzCoreConnect.Registrations.RegistrationWorkflow

  @user_role_types [
    {"Academic Officer", "academics"},
    {"Finance Officer", "finance"},
    {"Head Of Department(HOD)", "hod"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.modal id={"#{@id}-modal"} show on_cancel={JS.push("cancel_form_component", target: @myself) |> JS.exec("phx-remove", to: "##{@id}-modal")}>

        <:title>{if(@form_mode == :new, do: "Create New", else: "Edit")} Registration Work Flow</:title>

        <.form
          :let={f}
          for={@changeset}
          id="registration-flow-form"
          phx-submit="save"
          phx-change="validate"
          phx-target={@myself}
        >
          <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div>
              <.input
                field={f[:name]}
                label="Memo Type"
                class="w-full border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Enter registration type"
                required
              />
            </div>
            <div class="md:col-span-3">
              <.input
                field={f[:description]}
                label="Description"
                class="w-full border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Enter description"
              />
            </div>
            <div>
              <.input field={f[:is_active]} label="Active" type="checkbox" />
            </div>
            <div class="md:col-span-4">
              <% flow =
                if Map.has_key?(@changeset.changes, :flow), do: @changeset.changes.flow, else: [] %>
              <%= if is_list(flow) and length(flow) > 0 do %>
                <.inputs_for :let={fp} field={f[:flow]}>
                  <div class="flow-step bg-gray-100 p-4 rounded-lg border mb-4">
                    <div class="flex justify-between items-start mb-3">
                      <h4 class="font-bold">STEP: {fp.index + 1}</h4>
                      <.button
                        type="button"
                        phx-click="remove_step"
                        phx-value-index={fp.index}
                        class="text-red-500 hover:text-red-700"
                      >
                        <i class="fas fa-trash"></i>
                      </.button>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
                      <input type="hidden" name={flow[:step_no]} value={fp.index + 1} />
                      <div class="md:col-span-2">
                        <.input
                          field={fp[:description]}
                          label="Action Description"
                          placeholder="Enter action description"
                          required
                        />
                      </div>
                      <div class="md:col-span-2">
                        <.input
                          field={fp[:department_type]}
                          type="select"
                          label="Department/Unit"
                          options={[
                            {"Initiator Department", "initiator"},
                            {"Receiving Department", "receiving"},
                            {"Specific Department", "specific"}
                          ]}
                          prompt="-- Select department type --"
                          required
                        />
                      </div>
                      <%= if "#{fp.index}" in @specific_department do %>
                        <div class="md:col-span-4">
                          <.input
                            field={fp[:department_id]}
                            type="select"
                            label="Select Specific Department"
                            options={for department <- @specific_department_list, do: department}
                            prompt="-- Select Depatment --"
                            required
                          />
                        </div>
                      <% end %>
                      <div class="md:col-span-4">
                        <.input
                          field={fp[:required_titles]}
                          label="Select Required Titles (select in order of priority)"
                          type="select"
                          multiple
                          phx-hook="MultiSelect"
                          options={@specific_department_jobs["#{fp.index}"] || @user_role_types}
                          required
                        />
                      </div>
                    </div>
                  </div>
                </.inputs_for>
              <% else %>
                <div class="text-gray-500 text-center">
                  No workflow steps added yet. Click "Add Step" to get started.
                </div>
              <% end %>
            </div>
            <div class="md:col-span-4">
              <.button type="button" phx-click="add_step" class="mb-2">
                <.icon name="hero-plus-circle"/> Add Step
              </.button>
              <!-- Form Actions -->
              <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200">
                <.button type="button" id="cancel-button-2">
                  Cancel
                </.button>
                <.button type="submit">
                  Save Memo Flow
                </.button>
              </div>
            </div>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  @impl true
  def update(%{registration_workflow: registration_workflow} = assigns, socket) do
    registration_flow = %CuzCoreConnect.Registrations.RegistrationWorkflow{flow: []}

    changeset = CuzCoreConnect.Registrations.RegistrationWorkflow.changeset(registration_flow, %{})

    #     memo_flow = WorkFlows.get_memo_flows_by_id(id)


    # # Build the raw params list (including "id" for existing steps)
    # flow_params =
    #   memo_flow.flow
    #   |> Enum.map(fn step ->
    #     %{
    #       "id" => step.id,
    #       "step_no" => step.step_no,
    #       "description" => step.description,
    #       "department_type" => step.department_type,
    #       "required_titles" => step.required_titles,
    #       "department_id" => step.department_id
    #     }
    #   end)
    #   |> case do
    #     [] ->
    #       [
    #         %{
    #           "step_no" => 1,
    #           "description" => "",
    #           "department_type" => "initiator",
    #           "required_titles" => [],
    #           "department_id" => nil
    #         }
    #       ]

    #     steps ->
    #       steps
    #   end

    # # Build changeset so inputs_for will render these
    # changeset =
    #   MemoFlow.changeset(memo_flow, %{"flow" => flow_params})
    #   |> Map.put(:action, :validate)

    # # Now compute your LiveView assigns in one go
    # {specific_indices, jobs_by_index, selected_map} = build_specific_assigns(flow_params)

    # socket
    # |> assign(
    #   memos: true,
    #   hr: false,
    #   recovery: false,
    #   finance_budget: false,
    #   finance_payments: false,
    #   scholarship: false,
    #   changeset: changeset,
    #   memo_flow: memo_flow,
    #   flow_steps: flow_params,
    #   specific_department: specific_indices,
    #   specific_department_list: Departments.get_departments_input_list(),
    #   specific_department_jobs: jobs_by_index,
    #   selected_departments: selected_map
    # )


    socket =
      socket
      |> assign(
        registrations: true,
        changeset: changeset,
        specific_department: [],
        specific_department_jobs: %{},
        registration_flow: registration_flow,
        flow_steps: [%{description: "", department_type: "", required_titles: []}]
      )


    {:ok,
     socket
     |> assign(assigns)}
  end


  def handle_event("validate", %{"registration_flow" => registration_flow_params}, socket) do
    flow_params = registration_flow_params["flow"] || %{}

    {specific_indices, jobs_by_index, selected_map} =
      Enum.reduce(flow_params, {[], %{}, %{}}, fn {idx, step_params}, {inds, jobs, sels} ->
        sels =
          if step_params["department_type"] == "specific" do
            Map.put(sels, idx, step_params["department_id"] || "")
          else
            sels
          end

        jobs =
          if step_params["department_type"] == "specific" do
            dept_id = step_params["department_id"]

            titles =
              if !is_nil(dept_id) && dept_id != "" do
                case Jobs.list_jobs_by_department_id(dept_id) do
                  [] ->
                    []

                  jobs ->
                    jobs
                    |> Enum.map(&{&1.title, &1.title})
                    |> Enum.uniq()
                end
              else
                []
              end

            Map.put(jobs, idx, titles)
          else
            Map.delete(jobs, idx)
          end

        inds =
          if step_params["department_type"] == "specific", do: inds ++ [idx], else: inds

        {inds, jobs, sels}
      end)

    socket =
      socket
      |> assign(:specific_department, specific_indices)
      |> assign(:specific_department_list, Departments.get_departments_input_list())
      |> assign(:specific_department_jobs, jobs_by_index)
      |> assign(:selected_departments, selected_map)

    changeset =
      socket.assigns.registration_flow
      |> RegistrationWorkflow.changeset(registration_flow_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{
          "registration_flow" => %{
            "name" => name,
            "description" => description,
            "is_active" => is_active,
            "flow" => flow_map
          }
        },
        socket
      ) do
    flow_steps =
      flow_map
      |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
      |> Enum.with_index(1)
      |> Enum.map(fn {{_key, step_params}, step_no} ->
        %{
          step_no: step_no,
          description: step_params["description"],
          department_type: step_params["department_type"],
          required_titles: step_params["required_titles"] || [],
          department_id: step_params["department_id"] || nil
        }
      end)

    cleaned_params = %{
      name: name,
      description: description,
      is_active: is_active == "true",
      flow: flow_steps
    }

    case WorkFlows.create_registration_flow(cleaned_params) do
      {:ok, _registration_flow} ->
        {:noreply,
         socket
         |> put_flash(:info, "Memo flow created successfully")
         |> push_navigate(to: ~p"/administration/work_flows/registrations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("add_step", _, socket) do
    changeset = socket.assigns.changeset
    flow = Ecto.Changeset.get_field(changeset, :flow) || []
    step_no = length(flow) + 1

    new_step = %{
      step_no: step_no,
      description: "",
      department_type: "",
      department_id: nil,
      required_titles: []
    }

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(:flow, flow ++ [new_step])

    {:noreply,
     assign(socket,
       changeset: changeset,
       flow_steps: socket.assigns.flow_steps ++ [new_step]
     )}
  end

  def handle_event("remove_step", %{"index" => index}, socket) do
    index = String.to_integer(index)
    changeset = socket.assigns.changeset
    flow = Ecto.Changeset.get_field(changeset, :flow) || []

    updated_flow =
      flow
      |> List.delete_at(index)
      |> Enum.with_index()
      |> Enum.map(fn {step, idx} -> Map.put(step, :step_no, idx + 1) end)

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(:flow, updated_flow)

    {:noreply,
     assign(socket,
       changeset: changeset,
       flow_steps: updated_flow
     )}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("cancel_form_component", _, socket) do
    notify_parent(:cancel_form_component, "Form closed")
    {:noreply, socket}
  end

  defp notify_parent(key, msg), do: send(self(), {__MODULE__, {key, msg}})
end
