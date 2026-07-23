defmodule CuzCoreConnectWeb.Navigations.User do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Pages

  # Each entry: {page_name, label, icon, href, current_page_atom}
  # Grouped by role for the sidebar
  @nav_items %{
    "academics" => [
      {"academics_dashboard", "Dashboard", "chart-pie", "/academics/dashboard",
       :academics_dashboard},
      {"academics_pending_review", "Pending Review", "clock", "/academics/dashboard?tab=pending",
       :academics_pending_review},
      {"academics_approved", "Approved", "check-badge", "/academics/dashboard?tab=approved",
       :academics_approved}
    ],
    "finance" => [
      {"finance_dashboard", "Dashboard", "chart-pie", "/finance/dashboard", :finance_dashboard},
      {"finance_pending_payments", "Pending Payments", "banknotes",
       "/finance/dashboard?tab=pending", :finance_pending_payments},
      {"finance_verified", "Verified", "document-check", "/finance/dashboard?tab=approved",
       :finance_verified}
    ],
    "hod" => [
      {"hod_dashboard", "Dashboard", "chart-pie", "/hod/dashboard", :hod_dashboard},
      {"hod_pending_review", "Pending Review", "clock", "/hod/dashboard?tab=pending",
       :hod_pending_review},
      {"hod_approved", "Approved", "check-badge", "/hod/dashboard?tab=approved", :hod_approved}
    ],
    "retention" => [
      {"retention_dashboard", "Dashboard", "chart-pie", "/retention/dashboard",
       :retention_dashboard},
      {"retention_final_review", "Final Review", "clipboard-document-check",
       "/retention/dashboard?tab=pending", :retention_final_review},
      {"retention_completed", "Completed", "check-circle", "/retention/dashboard?tab=approved",
       :retention_completed}
    ],
    "student" => [
      {"student_dashboard", "Dashboard", "chart-pie", "/student/dashboard", :student_dashboard},
      {"student_my_registrations", "My Registrations", "document-text",
       "/student/dashboard?tab=my_registrations", :student_my_registrations},
      {"student_new_registration", "New Registration", "plus-circle",
       "/student/registrations/new", :student_new_registration},
      {"student_registration_tracking", "Track Registration", "magnifying-glass",
       "/registration/tracking", :student_registration_tracking}
    ],
    # Admin always sees everything — no access_map check needed
    "admin" => [
      {nil, "Dashboard", "chart-pie", "/admin/dashboard", :admin_dashboard},
      # {nil, "Students", "academic-cap", "/admin/student", :student_registrations},
      {nil, "Programmes", "book-open", "/admin/programmes", :programmes_management},
      {nil, "Courses", "rectangle-stack", "/admin/courses", :courses_management},
      {nil, "Workflows", "arrows-right-left", "/admin/workflows/registration",
       :registration_workflows},
      {nil, "Internal Accounts", "users", "/admin/user-accounts/internal", :internal_users},
      {nil, "External Accounts", "user-group", "/admin/user-accounts/external",
       :external_users},
      # {nil, "Attendance", "chart-bar", "/admin/reports/attendance", :reports_attendance},
      # {nil, "Performance", "chart-pie", "/admin/reports/performance", :reports_performance},
      {nil, "Messages", "chat-bubble-left-right", "/admin/messages", :messages},
      {nil, "Announcements", "megaphone", "/admin/announcements", :announcements}
    ]
  }

  def side_nav(assigns) do
    role = assigns.current_user.user_role

    # Build access map (skip DB call for admin — they see all)
    access_map =
      if role == "admin" do
        :all
      else
        Pages.build_access_map(assigns.current_user.id)
      end

    items = Map.get(@nav_items, role, [])

    visible_items =
      Enum.filter(items, fn {page_name, _label, _icon, _href, _atom} ->
        role == "admin" || Pages.can_access_page?(access_map, page_name)
      end)

    assigns =
      assigns
      |> Map.put(:visible_items, visible_items)
      |> Map.put(:role, role)

    ~H"""
    <aside
      id="sidebar"
      class="fixed inset-y-0 h-full left-0 w-64 border-r border-orange-500/10 shadow-2xl overflow-y-auto z-40"
    >
      <div class="flex flex-col h-full">
        <div class="flex justify-center pt-0.5 h-18">
          <div class="w-full flex items-center justify-center">
            <img
              src="/images/ccc_logo.png"
              alt="CUZ - CoreConnect Logo"
              class="h-26 w-auto object-contain relative pointer-events-none select-none"
              draggable="false"
            />
          </div>
        </div>

        <nav class="flex-1 px-4 py-8 space-y-1 overflow-y-auto scrollbar-thin scrollbar-thumb-orange-500/20 scrollbar-track-transparent border-t border-orange-500/10">
          <div class="menu-title mb-3">
            <span class="text-xs font-semibold uppercase tracking-wider text-base-content/40">
              {role_label(@role)}
            </span>
          </div>

          <%= for {_page_name, label, icon, href, page_atom} <- @visible_items do %>
            <.navigation_link
              href={href}
              active={@current_page == page_atom}
              icon={icon}
              label={label}
            />
          <% end %>

          <div class="divider my-4"></div>

          <.navigation_link
            href="/users/settings"
            active={@current_page == :user_settings}
            icon="cog-6-tooth"
            label="Account Settings"
          />
        </nav>
      </div>
    </aside>
    """
  end

  def top_nav(assigns) do
    ~H"""
    <div class="flex items-center">
      <h1 class="text-2xl font-bold">{String.upcase(@page_title)}</h1>
    </div>
    <div class="flex items-center justify-between px-6 py-4">
      <div class="flex items-center gap-4">
        <button
          id="sidebar-toggle"
          class="btn btn-ghost btn-sm lg:hidden"
          phx-click={JS.toggle(to: "#sidebar")}
        >
          <.icon name="hero-bars-3" class="w-5 h-5" />
        </button>
      </div>
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-6">
          <.live_component
            module={CuzCoreConnectWeb.NotificationBellComponent}
            id="user-notification-bell"
            current_scope={@current_scope}
            role={String.to_atom(@current_scope.user.user_role)}
          />

          <div :if={@current_scope && @current_scope.user} class="relative" id="user-menu-container">
            <button
              type="button"
              phx-click={toggle_dropdown("#user-dropdown-menu")}
              class="flex items-center gap-3 px-4 py-2 rounded-lg bg-base-300/10 hover:bg-base-300/30 transition-all duration-200 border border-primary/20"
            >
              <div class="relative">
                <img
                  class="h-9 w-9 rounded-full object-cover ring-2 ring-orange-200"
                  src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt={@current_scope.user.email}
                />
              </div>
              <div class="hidden md:block text-left">
                <p class="font-semibold text-base">
                  {@current_scope.user.username ||
                    @current_scope.user.email
                    |> String.split("@")
                    |> List.first()
                    |> String.capitalize()}
                </p>
                <p class="text-xs text-base-content/50">
                  {role_label(@current_scope.user.user_role)}
                </p>
              </div>
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>

            <div
              id="user-dropdown-menu"
              class="hidden absolute right-0 mt-2 w-full bg-base-100 rounded-lg shadow-xl border border-secondary/45 py-2 z-50"
            >
              <div class="px-4 py-3 border-b border-base-300">
                <p class="text-sm font-semibold text-orange-500">
                  {@current_scope.user.username ||
                    @current_scope.user.email
                    |> String.split("@")
                    |> List.first()
                    |> String.capitalize()}
                </p>
                <p class="text-xs mt-0.5 text-base-content/50">{@current_scope.user.email}</p>
                <span class="badge badge-xs badge-outline mt-1">
                  {role_label(@current_scope.user.user_role)}
                </span>
              </div>

              <.link
                navigate="/users/settings"
                class="px-4 py-2.5 text-sm hover:text-orange-600 hover:bg-orange-50 transition-all flex items-center gap-2"
              >
                <.icon name="hero-user-circle" class="w-5 h-5" /> Account Settings
              </.link>

              <div class="divider my-0"></div>

              <div class="px-1.5 py-1 flex justify-between items-center">
                <p class="px-3 text-sm font-semibold">Theme</p>
                <CuzCoreConnectWeb.Layouts.theme_toggle />
              </div>

              <.link
                href={~p"/users/log-out"}
                method="DELETE"
                class="border-t border-base-300 mt-1 flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
              >
                <.icon name="hero-arrow-right-start-on-rectangle" class="w-5 h-5 mr-3" /> Logout
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp role_label("admin"), do: "Administrator"
  defp role_label("academics"), do: "Academics"
  defp role_label("finance"), do: "Finance"
  defp role_label("hod"), do: "Head of Department"
  defp role_label("retention"), do: "Retention"
  defp role_label("student"), do: "Student"
  defp role_label(_), do: "User"
end
