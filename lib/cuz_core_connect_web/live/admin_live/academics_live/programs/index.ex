defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Programs.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Programs, as: Program
  alias CuzCoreConnectWeb.Admin.AcademicManagement.Programs.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    {:ok,
     socket
     |> stream(:programs, Academic.list_programs())
     |> assign(
       page_title: "Programs",
       current_page: :admin_programs,
       current_scope: current_scope
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Program")
    |> assign(:program, Academic.get_program!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Program")
    |> assign(:program, %Program{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Programs")
    |> assign(:program, nil)
  end

  @impl true
  def handle_info({CuzCoreConnectWeb.Admin.AcademicManagement.Programs.FormComponent, {:saved, program}}, socket) do
    {:noreply, stream_insert(socket, :programs, program)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    program = Academic.get_program!(id)
    {:ok, _} = Academic.delete_program(program)

    {:noreply, stream_delete(socket, :programs, program)}
  end
end
