defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Courses.FormComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Courses, as: Course

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Manage course details</:subtitle>
      </.header>

      <.form
        for={@form}
        id="course-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input field={@form[:code]} type="text" label="Code" required />
        <.input field={@form[:title]} type="text" label="Title" required />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:credits]} type="number" label="Credits" min="1" max="10" />
        <.input field={@form[:is_active]} type="checkbox" label="Active" />

        <%= if @action == :new do %>
          <div class="border-t border-base-200 pt-4 space-y-4">
            <p class="text-sm font-medium text-base-content/80">Programme assignment</p>
            <.input
              field={@form[:program_id]}
              type="select"
              label="Programme"
              prompt="Select a programme"
              options={@programme_options}
              required
            />
            <.input field={@form[:year]} type="number" label="Year" min="1" max="10" required />
            <.input
              field={@form[:semester]}
              type="select"
              label="Semester"
              options={[{"Semester 1", 1}, {"Semester 2", 2}]}
              required
            />
            <.input field={@form[:is_core]} type="checkbox" label="Core course" />
          </div>
        <% end %>

        <div class="flex justify-end space-x-2">
          <.link patch={~p"/admin/courses"}>
            <.button>Cancel</.button>
          </.link>

          <.button phx-disable-with="Saving...">Save Course</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{course: course} = assigns, socket) do
    programme_options =
      Academic.list_active_programs()
      |> Enum.map(&{"#{&1.code} — #{&1.name}", &1.id})

    changeset = change_course(course, %{}, assigns.action)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:programme_options, programme_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"courses" => course_params}, socket) do
    changeset =
      socket.assigns.course
      |> change_course(course_params, socket.assigns.action)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    changeset =
      socket.assigns.course
      |> change_course(params, socket.assigns.action)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"courses" => course_params}, socket) do
    save_course(socket, socket.assigns.action, course_params)
  end

  @impl true
  def handle_event("save", params, socket) do
    save_course(socket, socket.assigns.action, params)
  end

  defp save_course(socket, :edit, params) do
    case Academic.update_course(socket.assigns.course, params) do
      {:ok, course} ->
        notify_parent({:saved, course})

        {:noreply,
         socket
         |> put_flash(:info, "Course updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_course(socket, :new, params) do
    changeset =
      socket.assigns.course
      |> change_course(params, :new)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      {course_params, program_course_params} = split_course_params(params)

      case Academic.create_course_with_program(course_params, program_course_params) do
        {:ok, course} ->
          notify_parent({:saved, course})

          {:noreply,
           socket
           |> put_flash(:info, "Course created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = error_changeset} ->
          {:noreply, assign_form(socket, error_changeset)}
      end
    else
      {:noreply, assign_form(socket, changeset)}
    end
  end

  defp change_course(course, params, :new) do
    Course.create_with_program_changeset(course, params)
  end

  defp change_course(course, params, _action) do
    Academic.change_course(course, params)
  end

  defp split_course_params(params) do
    course_params = Map.take(params, ["title", "description", "code", "credits", "is_active"])

    program_course_params =
      Map.take(params, ["program_id", "year", "semester", "is_core"])

    {course_params, program_course_params}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
