defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Programmes, as: Programme
  alias CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:programmes, Academic.list_programs())
     |> assign(
       page_title: "Programmes",
       current_page: :programmes_management,
       id: "Programmes",
       search_placeholder: "Search Programmes...",
       programme: nil
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Programme")
    |> assign(:programme, Academic.get_program!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Programme Details")
    |> assign(:programme, Academic.get_program_with_courses!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Programme")
    |> assign(:programme, %Programme{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Programmes")
    |> assign(:programme, nil)
  end

  @impl true
  def handle_info(
        {CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.FormComponent,
         {:saved, programme}},
        socket
      ) do
    {:noreply, stream_insert(socket, :programmes, programme)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    programme = Academic.get_program!(id)
    {:ok, _} = Academic.delete_program(programme)

    {:noreply, stream_delete(socket, :programmes, programme)}
  end
end
