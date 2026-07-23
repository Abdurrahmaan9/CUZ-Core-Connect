defmodule CuzCoreConnectWeb.AdminLiveIndex do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:current_page, :admin_dashboard)
     |> assign(:active_tab, "overview")
     |> assign(:stats, get_admin_stats())
     |> assign(:recent_users, get_recent_users())
     |> assign(:workflows, get_workflows())}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket)
      when tab in ["overview", "users", "workflows", "settings"] do

    # current_page =
    #   cond do
    #     tab == "overview" -> :admin_dashboard
    #     tab == "users" -> :academics_pending_review
    #     tab == "workflows" -> :academics_approved
    #     tab == "settings" -> :academics_approved
    #   end

    {:noreply, assign(socket, :active_tab, tab)
    #  |> assign(:current_page, current_page)
    }
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :active_tab, "overview")}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/dashboard?tab=#{tab}")}
  end

  # Helper functions
  defp get_admin_stats do
    %{
      total_users: 156,
      active_workflows: 8,
      pending_requests: 23,
      system_health: "Good"
    }
  end

  defp get_recent_users do
    Accounts.list_recent_users(5)
  end

  defp get_workflows do
    [
      %{name: "Student Registration", description: "New student onboarding", status: "active"},
      %{name: "Course Enrollment", description: "Course selection workflow", status: "active"},
      %{name: "Faculty Approval", description: "Department approvals", status: "paused"}
    ]
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

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
