defmodule CuzCoreConnectWeb.Admin.WorkflowsComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 shadow-lg rounded-box">
      <div class="px-4 py-5 sm:p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-lg font-semibold text-base-content">Workflow Management</h3>
          <.link href={~p"/Admin/workflows/new"} class="btn btn-primary btn-sm">Create Workflow</.link>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="border border-base-300 rounded-box p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-base-content">Student Registration</h4>
              <div class="badge badge-success badge-sm">Active</div>
            </div>
            <p class="text-sm text-base-content/70 mb-4">Handles new student registration and approval workflows</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-base-content/50">245 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>

          <div class="border border-base-300 rounded-box p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-base-content">Course Enrollment</h4>
              <div class="badge badge-success badge-sm">Active</div>
            </div>
            <p class="text-sm text-base-content/70 mb-4">Manages course enrollment and prerequisite checking</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-base-content/50">89 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>

          <div class="border border-base-300 rounded-box p-6 hover:shadow-lg transition-shadow">
            <div class="flex items-center justify-between mb-4">
              <h4 class="text-lg font-medium text-base-content">Faculty Approval</h4>
              <div class="badge badge-warning badge-sm">Paused</div>
            </div>
            <p class="text-sm text-base-content/70 mb-4">Faculty and department approval workflows</p>
            <div class="flex justify-between items-center">
              <span class="text-xs text-base-content/50">12 requests this month</span>
              <.link href="#" class="text-primary text-sm font-medium">Manage</.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
