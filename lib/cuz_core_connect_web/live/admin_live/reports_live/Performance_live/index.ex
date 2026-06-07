defmodule CuzCoreConnectWeb.Admin.Reports.Performance do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Performance Reports",
       current_page: :reports_performance
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <Layouts.underconstruction_banner />
    </Layouts.user>

    """
  end
end
