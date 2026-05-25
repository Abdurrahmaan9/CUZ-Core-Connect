defmodule CuzCoreConnectWeb.Academics.Students.Registered do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnectWeb.Datatable.Pagination

  @filter_defaults %{
    search_filter: "",
    page: "",
    page_size: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Pending Registrations",
       current_page: :students_registered
     )
     |> Pagination.assign_filters(@filter_defaults)}
  end

  @impl true
  def handle_params(params, _url, socket) do

    {
      :noreply,
      socket
      |> Pagination.filter_composer(params)
      |> assign(:params, params)
    }
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    socket =
      socket
      |> Pagination.filter_composer(params)
      |> Pagination.push_filters(~p"/admin/student/registered")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <Layouts.underconstruction_banner />
    </Layouts.admin>

    """
  end
end
