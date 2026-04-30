defmodule CuzCoreConnectWeb.Navigations.Admin do
  use CuzCoreConnectWeb, :live_component

  def side_nav(assigns) do
    # user =
    #   assigns.current_user
    #   |> CuzCoreConnect.Repo.preload(merchant_users: :role)

    # page_access =
    #   if user.is_super_user do
    #     CuzCoreConnect.Pages.default_admin_page_access()
    #   else
    #     List.last(user.merchant_users).role.page_access
    #   end

    # assigns =
    #   assign(assigns,
    #     has_tab?: fn page ->
    #       Map.has_key?(page_access, page)
    #     end,
    #     has_dropdown_tab?: fn pages ->
    #       Enum.any?(pages, &Map.has_key?(page_access, &1))
    #     end,
    #     button_class: fn status ->
    #       if(status, do: "bg-indigo-900", else: "hover:bg-indigo-800 nav-item")
    #     end
    #   )

    ~H"""
    <aside class="fixed inset-y-0 h-full left-0 w-64 border-r border-orange-500/10 shadow-2xl overflow-y-auto z-40">
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

        <nav class="flex-1 px-4 py-8 space-y-2 overflow-y-auto scrollbar-thin scrollbar-thumb-orange-500/20 scrollbar-track-transparent border-t border-orange-500/10">
          <.navigation_link
            href="/admin/dashboard"
            active={@current_page == :admin_dashboard}
            icon="chart-pie"
            label="Dashboard"
          />

          <.navigation_link
            href="/students/registered"
            active={@current_page == :students_registered}
            icon="academic-cap"
            label="Registered Students"
          />

          <.navigation_link
            href="/students/pending"
            active={@current_page == :students_pending}
            icon="clock"
            label="Pending Registrations"
          />

          <.navigation_link
            href="/students/courses"
            active={@current_page == :students_courses}
            icon="book-open"
            label="Course Management"
          />

          <div class="divider my-4"></div>

          <div class="menu-title">
            <span class="text-sm font-medium text-base-content/70">Reports & Analytics</span>
          </div>

          <.navigation_link
            href="/reports/attendance"
            active={@current_page == :reports_attendance}
            icon="chart-bar"
            label="Attendance Reports"
          />

          <.navigation_link
            href="/reports/performance"
            active={@current_page == :reports_performance}
            icon="presentation-chart-bar"
            label="Performance Analytics"
          />

          <div class="divider my-4"></div>

          <div class="menu-title">
            <span class="text-sm font-medium text-base-content/70">Communication</span>
          </div>

          <.navigation_link
            href="/messages"
            active={@current_page == :messages}
            icon="chat-bubble-left-right"
            label="Messages"
          />

          <.navigation_link
            href="/announcements"
            active={@current_page == :announcements}
            icon="chat-megaphone"
            label="Announcements"
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
            id="admin-notification-bell"
            current_scope={@current_scope}
            role={:admin}
          />

          <div :if={@current_scope && @current_scope.user} class="relative" id="admin-menu-container">
            <button
              type="button"
              phx-click={toggle_dropdown("#admin-dropdown-menu")}
              class="flex items-center gap-3 px-4 py-2 rounded-lg bg-base-300/10 hover:bg-base-300/30 transition-all duration-200 border border-primary/20"
            >
              <div class="relative">
                <img
                  class="h-9 w-9 rounded-full object-cover ring-2 ring-orange-200 group-hover:ring-orange-400 transition-all duration-200"
                  src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt={@current_scope.user.email}
                />
              </div>
              <div class="hidden md:block text-left">
                <p class="font-semibold text-base">
                  {@current_scope.user.username ||
                    String.split(@current_scope.user.email, "@")
                    |> List.first()
                    |> String.capitalize()}
                </p>
                <p class="text-sm">{@current_scope.user.email}</p>
              </div>
              <svg
                class="w-4 h-4 text-base/80 transition-transform duration-200"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
                id="admin-dropdown-menu-chevron"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>

            <div
              id="admin-dropdown-menu"
              class="hidden absolute right-0 mt-2 w-full bg-base-100 rounded-lg shadow-xl border border-secondary/45 py-2 duration-200"
            >
              <div class="px-4 py-3 border-b border-gray-100">
                <p class="text-sm font-semibold text-orange-500">
                  {@current_scope.user.username ||
                    String.split(@current_scope.user.email, "@")
                    |> List.first()
                    |> String.capitalize()}
                </p>
                <p class="text-xs mt-1">{@current_scope.user.email}</p>
              </div>

              <.link
                navigate="/admin/settings/user"
                class="px-4 py-2.5 text-sm hover:text-orange-600 hover:bg-orange-50 transition-all duration-200 flex items-center gap-2"
              >
                <.icon name="hero-user-circle" class="w-5 h-5 mr-3" /> Account Settings
              </.link>

              <.link
                navigate="/admin/settings/system"
                class="px-4 py-2.5 text-sm hover:text-orange-600 hover:bg-orange-50 transition-all duration-200 flex items-center gap-2"
              >
                <.icon name="hero-cog" class="w-5 h-5 mr-3" /> System Settings
              </.link>

              <div class="divider"></div>

              <div class="px-1.5 flex justify-between">
                <p class="px-3 text-sm font-semibold">
                  Theme
                </p>
                <CuzCoreConnectWeb.Layouts.theme_toggle />
              </div>

              <div class="divider"></div>

              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
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
end
