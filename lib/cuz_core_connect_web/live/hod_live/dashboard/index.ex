defmodule CuzCoreConnectWeb.HODLive.Dashboard.Index do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "HOD Dashboard")
     |> assign(:current_page, :hod_dashboard)
     |> assign(:active_tab, "overview")}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket)
      when tab in ["overview", "pending", "approved"] do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, assign(socket, :active_tab, "overview")}

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/hod/dashboard?tab=#{tab}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <div class="border-b border-base-300 mb-6">
        <nav class="flex space-x-8 px-4">
          <%= for {label, tab} <- [{"Overview", "overview"}, {"Pending Review", "pending"}, {"Approved", "approved"}] do %>
            <button
              phx-click="switch_tab"
              phx-value-tab={tab}
              class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <>
                if(@active_tab == tab,
                  do: "border-primary text-primary",
                  else: "border-transparent text-base-content/50 hover:text-base-content")}
            >
              {label}
            </button>
          <% end %>
        </nav>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <.live_component
              module={CuzCoreConnectWeb.HODLive.Dashboard.OverviewComponent}
              id="hod-overview"
              current_scope={@current_scope}
            />
          <% "pending" -> %>
            <.live_component
              module={CuzCoreConnectWeb.HODLive.Dashboard.PendingRegistrationsComponent}
              id="hod-pending"
              current_scope={@current_scope}
            />
          <% "approved" -> %>
            <%!-- reuse same pattern --%>
            <p class="text-base-content/50 py-12 text-center">Approved registrations list here</p>
          <% _ -> %>
            <p class="text-center py-12 text-base-content/50">Tab not found</p>
        <% end %>
      </div>
    </Layouts.user>
    """
  end
end
