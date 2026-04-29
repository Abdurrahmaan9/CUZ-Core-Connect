defmodule CuzCoreConnectWeb.SysUser.Dashboard.Index do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
    socket
  |> assign(page_title: "Dashboard")
|> assign(current_page: :student_dashboard)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <div class="space-y-6">
        <!-- Welcome Section -->
        <div class="bg-gradient-to-r from-primary to-primary/80 text-white rounded-xl p-6 shadow-lg">
          <h1 class="text-3xl font-bold mb-2">
            Welcome back, {String.capitalize(@current_scope.user.username || " - ")}!
          </h1>
          <p class="text-white/90">Manage your academic dashboard and access key features</p>
        </div>

    <!-- Quick Stats -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-200">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-base-content/70">Total Students</p>
                <p class="text-2xl font-bold text-primary">247</p>
              </div>
              <.icon name="hero-academic-cap" class="w-8 h-8 text-primary/20" />
            </div>
          </div>

          <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-200">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-base-content/70">Pending Registrations</p>
                <p class="text-2xl font-bold text-warning">12</p>
              </div>
              <.icon name="hero-clock" class="w-8 h-8 text-warning/20" />
            </div>
          </div>

          <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-200">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-base-content/70">Active Courses</p>
                <p class="text-2xl font-bold text-success">18</p>
              </div>
              <.icon name="hero-book-open" class="w-8 h-8 text-success/20" />
            </div>
          </div>

          <div class="bg-base-100 rounded-lg p-4 shadow-sm border border-base-200">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-base-content/70">Messages</p>
                <p class="text-2xl font-bold text-info">5</p>
              </div>
              <.icon name="hero-chat-bubble-left-right" class="w-8 h-8 text-info/20" />
            </div>
          </div>
        </div>

    <!-- Recent Activity -->
        <div class="bg-base-100 rounded-lg p-6 shadow-sm border border-base-200">
          <h2 class="text-xl font-semibold mb-4">Recent Activity</h2>
          <div class="space-y-3">
            <div class="flex items-center gap-3 p-3 hover:bg-base-50 rounded-lg transition-colors">
              <div class="w-2 h-2 bg-success rounded-full"></div>
              <div class="flex-1">
                <p class="font-medium">New student registration approved</p>
                <p class="text-sm text-base-content/70">John Doe - Computer Science</p>
              </div>
              <span class="text-sm text-base-content/50">2 hours ago</span>
            </div>

            <div class="flex items-center gap-3 p-3 hover:bg-base-50 rounded-lg transition-colors">
              <div class="w-2 h-2 bg-warning rounded-full"></div>
              <div class="flex-1">
                <p class="font-medium">Course enrollment deadline approaching</p>
                <p class="text-sm text-base-content/70">Mathematics 101 - 3 days remaining</p>
              </div>
              <span class="text-sm text-base-content/50">5 hours ago</span>
            </div>

            <div class="flex items-center gap-3 p-3 hover:bg-base-50 rounded-lg transition-colors">
              <div class="w-2 h-2 bg-info rounded-full"></div>
              <div class="flex-1">
                <p class="font-medium">New announcement posted</p>
                <p class="text-sm text-base-content/70">Spring semester schedule update</p>
              </div>
              <span class="text-sm text-base-content/50">1 day ago</span>
            </div>
          </div>
        </div>

    <!-- Quick Actions -->
        <div class="bg-base-100 rounded-lg p-6 shadow-sm border border-base-200">
          <h2 class="text-xl font-semibold mb-4">Quick Actions</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <.link
              href={"/students/registered"}
              class="block p-4 bg-primary/5 rounded-lg hover:bg-primary/10 transition-colors border border-primary/20"
            >
              <.icon name="hero-users" class="w-6 h-6 text-primary mb-2" />
              <h3 class="font-medium text-primary">View All Students</h3>
              <p class="text-sm text-base-content/70 mt-1">Manage registered students</p>
            </.link>

            <.link
              href={"/students/pending"}
              class="block p-4 bg-warning/5 rounded-lg hover:bg-warning/10 transition-colors border border-warning/20"
            >
              <.icon name="hero-document-text" class="w-6 h-6 text-warning mb-2" />
              <h3 class="font-medium text-warning">Review Applications</h3>
              <p class="text-sm text-base-content/70 mt-1">12 pending registrations</p>
            </.link>

            <.link
              href={"/students/courses"}
              class="block p-4 bg-success/5 rounded-lg hover:bg-success/10 transition-colors border border-success/20"
            >
              <.icon name="hero-book-open" class="w-6 h-6 text-success mb-2" />
              <h3 class="font-medium text-success">Course Management</h3>
              <p class="text-sm text-base-content/70 mt-1">Manage course offerings</p>
            </.link>

            <.link
              href={"/reports/attendance"}
              class="block p-4 bg-info/5 rounded-lg hover:bg-info/10 transition-colors border border-info/20"
            >
              <.icon name="hero-chart-bar" class="w-6 h-6 text-info mb-2" />
              <h3 class="font-medium text-info">Attendance Reports</h3>
              <p class="text-sm text-base-content/70 mt-1">View attendance analytics</p>
            </.link>

            <.link
              href={"/messages"}
              class="block p-4 bg-secondary/5 rounded-lg hover:bg-secondary/10 transition-colors border border-secondary/20"
            >
              <.icon name="hero-chat-bubble-left-right" class="w-6 h-6 text-secondary mb-2" />
              <h3 class="font-medium text-secondary">Messages</h3>
              <p class="text-sm text-base-content/70 mt-1">5 unread messages</p>
            </.link>

            <.link
              href={"/announcements"}
              class="block p-4 bg-base-200 rounded-lg hover:bg-base-300 transition-colors"
            >
              <.icon name="hero-megaphone" class="w-6 h-6 text-base-content/70 mb-2" />
              <h3 class="font-medium">Announcements</h3>
              <p class="text-sm text-base-content/70 mt-1">Create and manage announcements</p>
            </.link>
          </div>
        </div>
      </div>
    </Layouts.user>
    """
  end
end
