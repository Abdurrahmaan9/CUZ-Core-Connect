defmodule CuzCoreConnectWeb.Navigations.Unauth do
  use CuzCoreConnectWeb, :live_component

  def header(assigns) do
    ~H"""
    <header class="border border-primary/25 backdrop-blur-sm sticky container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl top-0 z-50 bg-base-300/40 rounded-xl shadow-sm mt-5 mb-4">
      <div class="flex items-center justify-between py-4">
        <div class="flex items-center">
          <a href="/" class="flex items-center gap-2 text-xl font-bold text-primary">
            CUZ - Core Connect
          </a>
        </div>
        <ul class="flex items-center space-x-6">
          <li><a href="/#about" class="font-medium rounded-sm px-1 py-0.5 hover:bg-base-300">About</a></li>
          <li>
            <a href="/#developers" class="font-medium rounded-sm px-1 py-0.5 hover:bg-base-300">Developers</a>
          </li>
          <li>
            <a href="/#help-center" class="font-medium rounded-sm px-1 py-0.5 hover:bg-base-300">Help Center</a>
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
    </header>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer class="px-6 lg:px-20 py-10 text-sm text-base-content/60 mt-4">
      <div class="flex flex-col md:flex-row justify-between gap-4">
        <p>© 2026 CUZ - CoreConnect — Academic Workflow System</p>
        <p>Built with Elixir & Phoenix</p>
      </div>
    </footer>
    """
  end
end
