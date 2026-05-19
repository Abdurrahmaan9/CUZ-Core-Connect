defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Courses.FormComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Courses, as: Course

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
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

        <div class="flex justify-end space-x-2">
          <.link patch={~p"/admin/student/courses"}>
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
    changeset = Academic.change_course(course)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"courses" => course_params}, socket) do
    # Merge current params with existing course data
    updated_course =
      socket.assigns.course
      |> Map.merge(course_params, fn _k, v1, v2 ->
        if v2 == "" or v2 == nil, do: v1, else: v2
      end)

    changeset =
      updated_course
      |> Academic.change_course(course_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:course, updated_course)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Fallback for direct params (no nesting)
    updated_course =
      socket.assigns.course
      |> Map.merge(params, fn _k, v1, v2 ->
        if v2 == "" or v2 == nil, do: v1, else: v2
      end)

    changeset =
      updated_course
      |> Academic.change_course(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:course, updated_course)
     |> assign_form(changeset)}
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
    case Academic.create_course(params) do
      {:ok, course} ->
        notify_parent({:saved, course})

        {:noreply,
         socket
         |> put_flash(:info, "Course created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
