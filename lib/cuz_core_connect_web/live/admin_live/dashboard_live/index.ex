defmodule CuzCoreConnectWeb.AdminLiveIndex do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Registrations
  alias CuzCoreConnect.Workflows

  @impl true
  def mount(_params, _session, socket) do
    workflows = Workflows.list_registration_workflows()

    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:current_page, :admin_dashboard)
     |> assign(:active_tab, "overview")
     |> assign(:stats, get_admin_stats(workflows))
     |> assign(:recent_users, Accounts.list_recent_users(5))
     |> assign(:workflows, workflows)}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket)
      when tab in ["overview", "users", "workflows", "settings"] do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :active_tab, "overview")}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/dashboard?tab=#{tab}")}
  end

  defp get_admin_stats(workflows) do
    active_count = Enum.count(workflows, & &1.is_active)

    %{
      total_users: Accounts.count_users(),
      active_workflows: active_count,
      pending_requests: Registrations.count_pending_registrations(),
      system_health: "Good"
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <div class="mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <.live_component
              module={CuzCoreConnectWeb.AdminLiveOverviewComponent}
              id="overview"
              stats={@stats}
              recent_users={@recent_users}
              workflows={@workflows}
            />
          <% "users" -> %>
            <.live_component
              module={CuzCoreConnectWeb.AdminLiveAdminUsersComponent}
              id="admin-users"
            />
          <% "workflows" -> %>
            <.live_component
              module={CuzCoreConnectWeb.AdminLiveWorkflowsComponent}
              id="workflows"
              workflows={@workflows}
            />
          <% "settings" -> %>
            <.live_component
              module={CuzCoreConnectWeb.AdminLiveSettingsComponent}
              id="settings"
            />
          <% _ -> %>
            <div class="text-center py-12">
              <p class="text-base-content/50">Tab not found</p>
            </div>
        <% end %>
      </div>
    </Layouts.user>
    """
  end
end
