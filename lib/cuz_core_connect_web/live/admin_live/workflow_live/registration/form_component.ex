defmodule CuzCoreConnectWeb.Admin.RegistrationWorkflow.FormComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Workflows.RegistrationWorkflow
  alias CuzCoreConnect.Workflows
  alias CuzCoreConnect.NotifySubs

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
          class="p-6"
        >
          <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div>
              <.input
                field={f[:name]}
                label="Registration Type"
                placeholder="Enter registration type"
                required
              />
            </div>
            <div class="md:col-span-3">
              <.input
                field={f[:description]}
                label="Description"
                placeholder="Enter description"
              />
            </div>
              <div class="md:col-span-4 flex justify-end">
              <%!-- <.input field={f[:is_active]} label="Active" type="checkbox" /> --%>
              <.button type="button" phx-click="add_step" phx-target={@myself} class="gap-1 flex justify-center items-center mb-2 bg-green-400/30 px-1 pr-2 rounded rounded-sm">
                <.icon name="hero-plus" class="h-4 w-4"/> Step
              </.button>
            </div>
            <div class="md:col-span-4">
              <% flow =
                if Map.has_key?(@changeset.changes, :flow), do: @changeset.changes.flow, else: [] %>
              <%= if is_list(flow) and length(flow) > 0 do %>
                <.inputs_for :let={fp} field={f[:flow]}>
                  <div class="flow-step bg-gray-100/20 p-4 rounded-lg border border-secondary/20 mb-4">
                    <div class="flex justify-between items-start mb-3">
                      <h4 class="font-bold">STEP: {fp.index + 1}</h4>
                      <.button
                        type="button"
                        phx-click="remove_step"
                        phx-value-index={fp.index}
                        phx-target={@myself}
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
                          field={fp[:actionar_type]}
                          type="select"
                          label="Department/User Account"
                          options={[
                            {"Department", "specific_department"},
                            {"Specific User", "specific_user"}
                          ]}
                          prompt="-- Select department type --"
                          required
                        />
                      </div>
                      <%= if "#{fp.index}" in @specific_department do %>
                        <div class="md:col-span-4">
                          <.input
                            field={fp[:role_key]}
                            type="select"
                            label="Select Specific Department"
                            options={for department <- @specific_department_list, do: department}
                            prompt="-- Select Depatment --"
                            required
                          />
                        </div>
                      <% end %>
                      <%= if "#{fp.index}" in @specific_user do %>
                        <div class="md:col-span-4">
                          <.input
                            field={fp[:actioner_id]}
                            type="select"
                            label="Select Specific User"
                            options={for user <- @specific_user_list, do: user}
                            prompt="-- Select Depatment --"
                            required
                          />
                        </div>
                      <% end %>
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
              <!-- Form Actions -->
              <div class="flex justify-between space-x-3 pt-6 border-t border-gray-300/20">
                <.button type="button" id="cancel-button-2" phx-click="cancel_form_component" phx-target={@myself} class="bg-gray-50/75 px-1.5 rounded rounded-sm  text-black">
                  Cancel
                </.button>

                <.button
                  type="submit"
                  class="bg-indigo-600 text-white px-2 py-1 rounded-md hover:bg-indigo-700 transition flex items-center"
                >
                  Save Registration Flow
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
  def update(%{registration_workflow: registration_workflow, form_mode: _form_mode} = assigns, socket) do
    flow_params =
      registration_workflow.flow
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

    changeset =
      RegistrationWorkflow.changeset(registration_workflow, %{"flow" => flow_params})


    socket =
      socket
      |> assign(
        registrations: true,
        changeset: changeset,
        specific_department: [],
        specific_user: [],
        specific_user_list: [],
        specific_department_jobs: %{},
        user_role_types: @user_role_types,
        flow_steps: [%{description: "", actionar_type: "", required_titles: []}]
      )


    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", %{"registration_workflow" => registration_flow_params}, socket) do
    flow_params = registration_flow_params["flow"] || %{}

    IO.inspect(registration_flow_params, label: "===")
    {specific_indices, jobs_by_index, selected_map} =
      Enum.reduce(flow_params, {[], %{}, %{}}, fn {idx, step_params}, {inds, jobs, sels} ->
        sels =
          if step_params["actionar_type"] == "specific_department" do
            Map.put(sels, idx, step_params["role_key"] || "")
          else
            sels
          end

        jobs =
          if step_params["actionar_type"] == "specific_department" do

            Map.put(jobs, idx, @user_role_types)
          else
            Map.delete(jobs, idx)
          end

        inds =
          if step_params["actionar_type"] == "specific_department", do: inds ++ [idx], else: inds

        {inds, jobs, sels}
      end)

    socket =
      socket
      |> assign(:specific_department, specific_indices)
      |> assign(:specific_user, [])
      |> assign(:specific_user_list, [])
      |> assign(:specific_department_list, @user_role_types)
      |> assign(:specific_department_jobs, jobs_by_index)
      |> assign(:selected_departments, selected_map)

    changeset =
      socket.assigns.registration_workflow
      |> RegistrationWorkflow.changeset(registration_flow_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"registration_workflow" => workflow}, socket) do
    if socket.assigns.form_mode == :edit do
      save_edit_workflow(workflow, socket)
    else
      save_new_workflow(workflow, socket)
    end
  end

  def handle_event("add_step", _, socket) do
    changeset = socket.assigns.changeset
    flow = Ecto.Changeset.get_field(changeset, :flow) || []
    step_no = length(flow) + 1

    new_step = %{
      step_no: step_no,
      description: "",
      actionar_type: "",
      role_key: nil,
      actioner_id: nil,
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

  @impl true
  def handle_event("cancel_form_component", _, socket) do
    notify_parent(:cancel_form_component, "Form closed")
    {:noreply, socket}
  end

  def save_new_workflow(workflow, socket) do
    flow_steps =
      (workflow["flow"] || %{})
      |> Enum.sort_by(fn {k, _} -> String.to_integer(k) end)
      |> Enum.with_index(1)
      |> Enum.map(fn {{_key, step_params}, step_no} ->
        %{
          step_no: step_no,
          description: step_params["description"],
          actionar_type: step_params["actionar_type"],
          required_titles: step_params["required_titles"] || [],
          role_key: step_params["role_key"] || nil,
          actioner_id: step_params["actioner_id"] || nil
        }
      end)

    cleaned_params =
      %{
        name: workflow["name"] || "N/A",
        description: workflow["description"] || "N/A",
        is_active: (workflow["is_active"] || "false") == "true",
        flow: flow_steps
      }

    case Workflows.create_registration_flow(cleaned_params) do
      {:ok, _registration_flow} ->
        notify_parent(:success, "Registration flow created successfully")
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, msg} = NotifySubs.notify_subs({:error, changeset})
        notify_parent(:error, "Failed to create flow: #{msg}")
        {:noreply, socket}
    end
  end

  def save_edit_workflow(workflow, socket) do
    case Workflows.update_registration_flow(socket.assigns.registration_workflow, workflow) do
      {:ok, _registration_workflow} ->
        notify_parent(:success, "Registration flow updated successfully")
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, msg} = NotifySubs.notify_subs({:error, changeset})
        notify_parent(:error, "Failed to create flow: #{msg}")
        {:noreply, socket}
    end
  end

  defp notify_parent(key, msg), do: send(self(), {__MODULE__, {key, msg}})
end
