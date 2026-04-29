defmodule CuzCoreConnectWeb.AdminLiveOverviewComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-primary/10 p-3 rounded-full">
              <.icon name="hero-users" class="h-6 w-6 text-primary" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-base-content/70 truncate">Total Users</dt>
                <dd class="text-lg font-semibold text-base-content">{@stats.total_users}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-success/10 p-3 rounded-full">
              <.icon name="hero-cog" class="h-6 w-6 text-success" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-base-content/70 truncate">Active Workflows</dt>
                <dd class="text-lg font-semibold text-base-content">{@stats.active_workflows}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-warning/10 p-3 rounded-full">
              <.icon name="hero-document-text" class="h-6 w-6 text-warning" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-base-content/70 truncate">Pending Requests</dt>
                <dd class="text-lg font-semibold text-base-content">{@stats.pending_requests}</dd>
              </dl>
            </div>
          </div>
        </div>

        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-info/10 p-3 rounded-full">
              <.icon name="hero-chart-bar" class="h-6 w-6 text-info" />
            </div>
            <div class="ml-5 w-0 flex-1">
              <dl>
                <dt class="text-sm font-medium text-base-content/70 truncate">System Health</dt>
                <dd class="text-lg font-semibold text-base-content">Good</dd>
              </dl>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <h3 class="text-lg font-semibold text-base-content mb-4">Recent Users</h3>
          <div class="space-y-3">
            <%= for user <- @recent_users do %>
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class="avatar placeholder">
                    <div class="bg-neutral text-neutral-content rounded-full w-10 h-10">
                      <span class="text-sm font-medium">
                        {String.first(user.email)}
                      </span>
                    </div>
                  </div>
                  <div class="ml-4">
                    <p class="text-sm font-medium text-base-content">{user.email}</p>
                    <p class="text-xs text-base-content/50">Role: {user.user_role}</p>
                  </div>
                </div>
                <div class="text-xs text-base-content/50">
                  {format_date(user.inserted_at)}
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="bg-base-100 p-6 rounded-box shadow-lg">
          <h3 class="text-lg font-semibold text-base-content mb-4">Workflow Status</h3>
          <div class="space-y-3">
            <%= for workflow <- @workflows do %>
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-base-content">{workflow.name}</p>
                  <p class="text-xs text-base-content/50">{workflow.description}</p>
                </div>
                <div class={"badge badge-sm " <>
                  if(workflow.status == "active", do: "badge-success", else: "badge-neutral")}>
                  {workflow.status}
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
