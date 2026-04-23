defmodule CuzCoreConnectWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use CuzCoreConnectWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 right-0 z-50 container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl bg-base-100/60 backdrop-blur-sm rounded-xl shadow-sm mt-5">
    <!-- <header class="fixed top-0 left-0 right-0 z-50 container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl bg-white rounded-xl shadow-sm mt-5"> -->
      <div class="flex items-center justify-between py-4">
        <div class="flex items-center">
          <a href="/" class="flex items-center gap-2 text-xl font-bold text-primary">
            UniFlow
          </a>
        </div>
        <ul class="flex items-center space-x-6">
          <li><a href="#" class="font-medium text-gray-600 hover:text-gray-900">About</a></li>
          <li><a href="#" class="font-medium text-gray-600 hover:text-gray-900">Developers</a></li>
          <li><a href="#" class="font-medium text-gray-600 hover:text-gray-900">Help Center</a></li>
        </ul>
        <div class="flex items-center space-x-3">
          <.theme_toggle />
          <%= if @current_scope && @current_scope.user do %>
            <div class="dropdown dropdown-end">
              <label tabindex="0" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full">
                  <div class="bg-neutral text-neutral-content rounded-full w-10 h-10 flex items-center justify-center">
                    <span class="text-sm font-medium">
                      {String.first(@current_scope.user.email)}
                    </span>
                  </div>
                </div>
              </label>
              <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
                <li class="menu-title">
                  <span class="text-base-content/70 font-normal">{@current_scope.user.email}</span>
                </li>
                <div class="divider my-1"></div>
                <%= if @current_scope.user.user_role == "Admin" do %>
                  <li>
                    <.link href={~p"/Admin/Dashboard"} class="text-base-content">
                      <.icon name="hero-cog-6-tooth" class="w-4 h-4" />
                      Admin Dashboard
                    </.link>
                  </li>
                <% end %>
                <li>
                  <.link href={~p"/users/settings"} class="text-base-content">
                    <.icon name="hero-cog-8-tooth" class="w-4 h-4" />
                    Settings
                  </.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="text-base-content">
                    <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4" />
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          <% else %>
            <.link href={~p"/users/log-in"} class="btn btn-outline border-gray-300 text-gray-700 hover:bg-gray-50">Log In</.link>
            <.link href={~p"/users/register"} class="btn bg-primary text-white hover:bg-orange-600 border-transparent">Sign Up</.link>
          <% end %>
        </div>
      </div>
    </header>

    <main class="px-4 pt-32 pb-20 sm:px-6 lg:px-8">
      <div class="mx-auto w-full space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders user layout with sidebar for non-admin users.

  This layout includes a sidebar with navigation for managing students,
  courses, reports, and communication features.

  ## Examples

      <Layouts.user flash={@flash} current_scope={@current_scope}>
        <h1>User Dashboard Content</h1>
      </Layouts.user>

  """
  def user(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 right-0 z-50 bg-base-100/60 backdrop-blur-sm border-b border-base-200">
      <div class="flex items-center justify-between px-6 py-4">
        <div class="flex items-center gap-4">
          <button
            id="sidebar-toggle"
            class="btn btn-ghost btn-sm lg:hidden"
            phx-click={JS.toggle(to: "#sidebar")}
          >
            <.icon name="hero-bars-3" class="w-5 h-5" />
          </button>
          <a href="/" class="flex items-center gap-2 text-xl font-bold text-primary">
            UniFlow
          </a>
        </div>
        <div class="flex items-center gap-3">
          <.theme_toggle />
          <%= if @current_scope && @current_scope.user do %>
            <div class="dropdown dropdown-end">
              <label tabindex="0" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full">
                  <div class="bg-neutral text-neutral-content rounded-full w-10 h-10 flex items-center justify-center">
                    <span class="text-sm font-medium">
                      {String.first(@current_scope.user.email)}
                    </span>
                  </div>
                </div>
              </label>
              <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
                <li class="menu-title">
                  <span class="text-base-content/70 font-normal">{@current_scope.user.email}</span>
                </li>
                <div class="divider my-1"></div>
                <li>
                  <.link href={~p"/users/settings"} class="text-base-content">
                    <.icon name="hero-cog-8-tooth" class="w-4 h-4" />
                    Settings
                  </.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="text-base-content">
                    <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4" />
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
    </header>

    <div class="flex pt-16">
      <!-- Sidebar -->
      <aside id="sidebar" class="fixed left-0 top-16 bottom-0 w-64 bg-base-100 border-r border-base-200 transform -translate-x-full lg:translate-x-0 transition-transform duration-300 ease-in-out z-40">
        <nav class="p-4 space-y-2">
          <div class="menu-title">
            <span class="text-sm font-medium text-base-content/70">Academic Management</span>
          </div>

          <li>
            <.link href={~p"/students/registered"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-academic-cap" class="w-5 h-5" />
              <span>Registered Students</span>
            </.link>
          </li>

          <li>
            <.link href={~p"/students/pending"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-clock" class="w-5 h-5" />
              <span>Pending Registrations</span>
            </.link>
          </li>

          <li>
            <.link href={~p"/students/courses"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-book-open" class="w-5 h-5" />
              <span>Course Management</span>
            </.link>
          </li>

          <div class="divider my-4"></div>

          <div class="menu-title">
            <span class="text-sm font-medium text-base-content/70">Reports & Analytics</span>
          </div>

          <li>
            <.link href={~p"/reports/attendance"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-chart-bar" class="w-5 h-5" />
              <span>Attendance Reports</span>
            </.link>
          </li>

          <li>
            <.link href={~p"/reports/performance"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-chart-pie" class="w-5 h-5" />
              <span>Performance Analytics</span>
            </.link>
          </li>

          <div class="divider my-4"></div>

          <div class="menu-title">
            <span class="text-sm font-medium text-base-content/70">Communication</span>
          </div>

          <li>
            <.link href={~p"/messages"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-chat-bubble-left-right" class="w-5 h-5" />
              <span>Messages</span>
            </.link>
          </li>

          <li>
            <.link href={~p"/announcements"} class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-base-200 transition-colors">
              <.icon name="hero-megaphone" class="w-5 h-5" />
              <span>Announcements</span>
            </.link>
          </li>
        </nav>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 lg:ml-64 min-h-screen bg-base-50">
        <div class="p-6">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <!-- Overlay for mobile sidebar -->
    <div
      id="sidebar-overlay"
      class="fixed inset-0 bg-black/50 z-30 hidden lg:hidden"
      phx-click={JS.toggle(to: "#sidebar") |> JS.toggle(to: "#sidebar-overlay")}
    ></div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
