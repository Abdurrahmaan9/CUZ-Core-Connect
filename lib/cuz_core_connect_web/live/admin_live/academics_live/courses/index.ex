defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Courses.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Courses, as: Course
  alias CuzCoreConnectWeb.Admin.AcademicManagement.Courses.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    {:ok,
     socket
     |> stream(:courses, Academic.list_courses())
     |> assign(
       page_title: "Courses",
       current_page: :admin_courses,
       current_scope: current_scope
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Course")
    |> assign(:course, Academic.get_course!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Course")
    |> assign(:course, %Course{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Courses")
    |> assign(:course, nil)
  end

  @impl true
  def handle_info({CuzCoreConnectWeb.Admin.AcademicManagement.Courses.FormComponent, {:saved, course}}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    course = Academic.get_course!(id)
    {:ok, _} = Academic.delete_course(course)

    {:noreply, stream_delete(socket, :courses, course)}
  end
end
