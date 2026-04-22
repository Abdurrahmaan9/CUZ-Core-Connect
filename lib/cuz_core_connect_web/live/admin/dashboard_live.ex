defmodule CuzCoreConnectWeb.Admin.DashboardLive do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Check if current user is admin
    current_scope = socket.assigns[:current_scope]

    if current_scope && current_scope.user.user_role == "Admin" do
      {:ok,
       socket
       |> assign(:page_title, "Admin Dashboard")
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
    {:noreply, push_patch(socket, to: ~p"/Admin/Dashboard?tab=#{tab}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gray-50">
        <!-- Admin Header -->
        <div class="bg-white shadow-sm border-b">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center py-6">
              <div>
                <h1 class="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
                <p class="text-sm text-gray-600 mt-1">System Administration & Workflow Management</p>
              </div>
              <div class="flex items-center space-x-4">
                <span class="text-sm text-gray-600">Admin: {@current_scope.user.email}</span>
                <.link href={~p"/users/settings"} class="btn btn-ghost btn-sm">Settings</.link>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab Navigation -->
        <div class="bg-white border-b">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <nav class="flex space-x-8">
              <button
                phx-click="switch_tab"
                phx-value-tab="overview"
                class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <>
                  if(@active_tab == "overview", do: "border-primary text-primary", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")}
              >
                Overview
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="users"
                class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <>
                  if(@active_tab == "users", do: "border-primary text-primary", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")}
              >
                User Management
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="workflows"
                class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <>
                  if(@active_tab == "workflows", do: "border-primary text-primary", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")}
              >
                Workflow Management
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="settings"
                class={"py-4 px-1 border-b-2 font-medium text-sm transition-colors " <>
                  if(@active_tab == "settings", do: "border-primary text-primary", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")}
              >
                System Settings
              </button>
            </nav>
          </div>
        </div>

        <!-- Tab Content -->
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <%= case @active_tab do %>
            <% "overview" -> %>
              <.overview_tab stats={@stats} recent_users={@recent_users} workflows={@workflows} />
            <% "users" -> %>
              <.users_tab />
            <% "workflows" -> %>
              <.workflows_tab />
            <% "settings" -> %>
              <.settings_tab />
            <% _ -> %>
              <div class="text-center py-12">
                <p class="text-gray-500">Tab not found</p>
              </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp overview_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-white p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-primary/10 p-3 rounded-full">
              <.icon name="hero-users" class="h-6 w-6 text-primary" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-gray-500 truncate">Total Users</dt>
                <dd class="text-lg font-semibold text-gray-900">{@stats.total_users}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-green-100 p-3 rounded-full">
              <.icon name="hero-cog" class="h-6 w-6 text-green-600" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-gray-500 truncate">Active Workflows</dt>
                <dd class="text-lg font-semibold text-gray-900">{@stats.active_workflows}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-yellow-100 p-3 rounded-full">
              <.icon name="hero-document-text" class="h-6 w-6 text-yellow-600" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-gray-500 truncate">Pending Requests</dt>
                <dd class="text-lg font-semibold text-gray-900">{@stats.pending_requests}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-blue-100 p-3 rounded-full">
              <.icon name="hero-chart-bar" class="h-6 w-6 text-blue-600" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-gray-500 truncate">System Health</dt>
                <dd class="text-lg font-semibold text-gray-900">Good</dd>
              </dl>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Recent Users</h3>
          <div class="space-y-3">
            <%= for user <- @recent_users do %>
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class="flex-shrink-0 h-10 w-10 bg-gray-200 rounded-full flex items-center justify-center">
                    <span class="text-sm font-medium text-gray-600">
                      {String.first(user.email)}
                    </span>
                  </div>
                  <div class="ml-4">
                    <p class="text-sm font-medium text-gray-900">{user.email}</p>
                    <p class="text-xs text-gray-500">Role: {user.user_role}</p>
                  </div>
                </div>
                <div class="text-xs text-gray-500">
                  {format_date(user.inserted_at)}
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Workflow Status</h3>
          <div class="space-y-3">
            <%= for workflow <- @workflows do %>
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-900">{workflow.name}</p>
                  <p class="text-xs text-gray-500">{workflow.description}</p>
                </div>
                <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium " <>
                  if(workflow.status == "active", do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")}>
                  {workflow.status}
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp users_tab(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-4 py-5 sm:p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">User Management</h3>
          <.link href={~p"/Admin/users/new"} class="btn btn-primary btn-sm">Add User</.link>
        </div>

        <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
          <table class="min-w-full divide-y divide-gray-300">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide">User</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide">Role</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide">Created</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wide">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10">
                      <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                        <span class="text-sm font-medium text-gray-600">JD</span>
                      </div>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">john.doe@university.edu</div>
                      <div class="text-sm text-gray-500">John Doe</div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                    Academics
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                    Active
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">2 days ago</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <.link href="#" class="text-primary hover:text-primary/90 mr-3">Edit</.link>
                  <.link href="#" class="text-red-600 hover:text-red-900">Delete</.link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp workflows_tab(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-4 py-5 sm:p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Workflow Management</h3>
          <.link href={~p"/Admin/workflows/new"} class="btn btn-primary btn-sm">Create Workflow</.link>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="border rounded-lg p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-gray-900">Student Registration</h4>
              <span class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">Active</span>
            </div>
            <p class="text-sm text-gray-600 mb-4">Handles new student registration and approval workflows</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">245 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>

          <div class="border rounded-lg p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-gray-900">Course Enrollment</h4>
              <span class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">Active</span>
            </div>
            <p class="text-sm text-gray-600 mb-4">Manages course enrollment and prerequisite checking</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">89 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>

          <div class="border rounded-lg p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-gray-900">Faculty Approval</h4>
              <span class="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">Paused</span>
            </div>
            <p class="text-sm text-gray-600 mb-4">Faculty and department approval workflows</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">12 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp settings_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-6">System Configuration</h3>

          <div class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-gray-700">System Name</label>
              <input type="text" value="UniFlow" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary focus:border-primary" />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Default User Role</label>
              <select class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary focus:border-primary">
                <option>Academics</option>
                <option>Student</option>
                <option>Finance</option>
                <option>HOD</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Email Notifications</label>
              <div class="mt-2 space-y-2">
                <label class="flex items-center">
                  <input type="checkbox" checked class="rounded border-gray-300 text-primary shadow-sm focus:border-primary focus:ring focus:ring-primary focus:ring-opacity-25" />
                  <span class="ml-2 text-sm text-gray-700">Enable email notifications</span>
                </label>
                <label class="flex items-center">
                  <input type="checkbox" checked class="rounded border-gray-300 text-primary shadow-sm focus:border-primary focus:ring focus:ring-primary focus:ring-opacity-25" />
                  <span class="ml-2 text-sm text-gray-700">Send registration confirmations</span>
                </label>
              </div>
            </div>

            <div class="pt-4">
              <button type="button" class="btn btn-primary">Save Changes</button>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 mb-6">Backup & Maintenance</h3>

          <div class="space-y-4">
            <div class="flex justify-between items-center">
              <div>
                <p class="text-sm font-medium text-gray-900">Last Backup</p>
                <p class="text-sm text-gray-500">2 hours ago</p>
              </div>
              <button class="btn btn-outline btn-sm">Run Backup</button>
            </div>

            <div class="flex justify-between items-center">
              <div>
                <p class="text-sm font-medium text-gray-900">System Maintenance</p>
                <p class="text-sm text-gray-500">Schedule regular maintenance</p>
              </div>
              <button class="btn btn-outline btn-sm">Configure</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
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
    [
      %{email: "john.doe@university.edu", user_role: "Academics", inserted_at: DateTime.add(DateTime.utc_now(), -86400)},
      %{email: "jane.smith@university.edu", user_role: "Finance", inserted_at: DateTime.add(DateTime.utc_now(), -172800)},
      %{email: "mike.wilson@university.edu", user_role: "HOD", inserted_at: DateTime.add(DateTime.utc_now(), -259200)}
    ]
  end

  defp get_workflows do
    [
      %{name: "Student Registration", description: "New student onboarding", status: "active"},
      %{name: "Course Enrollment", description: "Course selection workflow", status: "active"},
      %{name: "Faculty Approval", description: "Department approvals", status: "paused"}
    ]
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
