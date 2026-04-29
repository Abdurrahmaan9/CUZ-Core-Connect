defmodule CuzCoreConnectWeb.Admin.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # Check if current user is admin
    current_scope = socket.assigns[:current_scope]

    if current_scope && current_scope.user.user_role == "Admin" do
      {:ok,
       socket
       |> assign(:page_title, "Admin Dashboard")
       |> assign(:current_page, :admin_dashboard)
       |> assign(:active_tab, "overview")
       |> assign(:stats, get_admin_stats())
       |> assign(:recent_users, get_recent_users())
       |> assign(:workflows, get_workflows())}
    else
      {:ok,
       socket
       |> put_flash(:error, "Access denied. Admin privileges required.")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket) when tab in ["overview", "users", "workflows", "settings"] do
    {:noreply, assign(socket, :active_tab, tab)}
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
end
