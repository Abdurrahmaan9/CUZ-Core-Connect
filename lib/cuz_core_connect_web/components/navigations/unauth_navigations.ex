defmodule CuzCoreConnectWeb.Navigations.Unauth do
  use CuzCoreConnectWeb, :live_component

  def header(assigns) do
    ~H"""
    <div class="mb-20"></div>
    <%!-- <header class="border border-primary/25 backdrop-blur-sm sticky container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl top-0 z-50 bg-base-300/40 rounded-xl shadow-sm mt-5 mb-4"> --%>
    <%!-- <header class="backdrop-blur-md sticky container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl top-0 z-50 border-b border-orange-400 bg-gray-200/10 rounded-xl shadow-sm mt-5 mb-4"> --%>
    <header class="fixed top-0 left-0 right-0 z-50 container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl border border-primary/25 bg-base-100/60 backdrop-blur-sm rounded-xl shadow-sm mt-5">
      <div class="flex items-center justify-between py-4">
        <div class="flex items-center">
          <a href="/" class="flex items-center gap-2 text-xl font-bold text-primary">
            CUZ - Core Connect
          </a>
        </div>

        <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center space-x-6">
          <ul class="flex items-center space-x-6">
            <li><a href="/#about" class="font-medium rounded-sm px-1 py-0.5 hover:text-primary transition-colors duration-300">About</a></li>
            <li>
              <a href="/#developers" class="font-medium rounded-sm px-1 py-0.5 hover:text-primary transition-colors duration-300">Developers</a>
            </li>
            <li>
              <a href="/#help-center" class="font-medium rounded-sm px-1 py-0.5 hover:text-primary transition-colors duration-300">Help Center</a>
            </li>
          </ul>
          <div class="flex items-center space-x-3">
            <CuzCoreConnectWeb.Layouts.theme_toggle />

            <.link href={~p"/users/log-in"} class="btn btn-outline border-gray-300 hover:bg-base-300">
              Log In
            </.link>
            <.link
              href={~p"/users/register"}
              class="btn bg-primary text-white hover:bg-orange-600 border-transparent"
            >
              Sign Up
            </.link>
          </div>
        </div>

        <!-- Mobile Menu Button -->
        <div class="md:hidden">
          <button
            type="button"
            phx-click="toggle_mobile_menu"
            class="p-2 rounded-lg hover:bg-base-200 transition-colors"
            aria-label="Toggle mobile menu"
          >
            <.icon name="hero-bars-3" class="w-6 h-6 text-base-content" />
          </button>
        </div>
      </div>

      <!-- Mobile Menu -->
      <%= if @show_mobile_menu do %>
        <div class="md:hidden border-t border-base-200 bg-base-100/95 backdrop-blur-sm mt-4 -mx-4 px-4 py-4 rounded-b-xl">
          <nav class="space-y-4">
            <div class="space-y-2">
              <a href="/#about" class="block font-medium rounded-sm px-2 py-2 hover:bg-base-200">About</a>
              <a href="/#developers" class="block font-medium rounded-sm px-2 py-2 hover:bg-base-200">Developers</a>
              <a href="/#help-center" class="block font-medium rounded-sm px-2 py-2 hover:bg-base-200">Help Center</a>
            </div>
            <div class="border-t border-base-200 pt-4 space-y-2">
              <div class="flex items-center justify-between">
                <span class="text-sm text-base-content/70">Theme</span>
                <CuzCoreConnectWeb.Layouts.theme_toggle />
              </div>
              <.link href={~p"/users/log-in"} class="block w-full btn btn-outline border-gray-300 hover:bg-base-300 text-center">
                Log In
              </.link>
              <.link
                href={~p"/users/register"}
                class="block w-full btn bg-primary text-white hover:bg-orange-600 border-transparent text-center"
              >
                Sign Up
              </.link>
            </div>
          </nav>
        </div>
      <% end %>
    </header>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="px-6 lg:px-20 py-10 text-sm text-base-content/60 mt-4">
      <div class="flex flex-col md:flex-row justify-between gap-4 text-xs">
        <p>© 2026 CUZ - Core Connect — Academic Workflow System</p>
        <p>Built with Elixir & Phoenix</p>
      </div>
    </footer>
    """
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end
end
