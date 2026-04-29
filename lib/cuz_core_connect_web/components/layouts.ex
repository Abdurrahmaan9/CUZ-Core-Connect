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
  Renders your unauth layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.unauth flash={@flash}>
        <h1>Content</h1>
      </Layouts.unauth>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  slot :header
  slot :footer

  def unauth(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      {render_slot(@header)}
      <main class="flex-1 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-full space-y-4">
          {render_slot(@inner_block)}
        </div>
      </main>
      {render_slot(@footer)}
    </div>
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
    <header class="h-18 fixed top-0 bg-base-100/90 backdrop-blur-lg left-64 right-0 p-4 inset-x-0 z-50 flex justify-between shadow-md">
      <CuzCoreConnectWeb.Navigations.User.top_nav
        current_scope={@current_scope}
        page_title={@page_title}
      />
    </header>

    <div class="pt-16 flex min-h-screen w-full">
      <CuzCoreConnectWeb.Navigations.User.side_nav
        current_user={@current_scope.user}
        current_page={@current_page}
      />
      <main class="w-full p-6 md:ml-64">
        <div class="min-h-screen">
          <.flash_group flash={@flash} />
          <div class="mx-auto max-w-full space-y-4 p-4">
            {render_slot(@inner_block)}
          </div>
        </div>
      </main>
      <%= if @current_scope && @current_scope.user do %>
      <.live_component
        module={CuzCoreConnectWeb.Components.SessionTimerComponent}
        id="session-timer-admin"
      />
    <% end %>
    </div>

    <!-- Overlay for mobile sidebar -->
    <div
      id="sidebar-overlay"
      class="fixed inset-0 bg-black/50 z-30 hidden lg:hidden"
      phx-click={JS.toggle(to: "#sidebar") |> JS.toggle(to: "#sidebar-overlay")}
    ></div>
    """
  end

  @doc """
  Renders admin layout with sidebar for non-admin users.

  This layout includes a sidebar with navigation for managing students,
  courses, reports, and communication features.

  ## Examples

      <Layouts.user flash={@flash} current_scope={@current_scope}>
        <h1>User Dashboard Content</h1>
      </Layouts.user>

  """

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :page_title, :string, required: true, doc: "the title thats going to display"
  attr :current_page, :atom, required: true, doc: "the active page"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <header class="h-18 fixed top-0 bg-base-100/90 backdrop-blur-lg left-64 right-0 p-4 inset-x-0 z-50 flex justify-between shadow-md">
      <CuzCoreConnectWeb.Navigations.Admin.top_nav
        current_scope={@current_scope}
        page_title={@page_title}
      />
    </header>

    <div class="pt-16 flex min-h-screen w-full">
      <CuzCoreConnectWeb.Navigations.Admin.side_nav
        current_user={@current_scope.user}
        current_page={@current_page}
      />
      <main class="w-full p-6 md:ml-64">
        <div class="min-h-screen">
          <.flash_group flash={@flash} />
          <div class="mx-auto max-w-full space-y-4 p-4">
            {render_slot(@inner_block)}
          </div>
        </div>
      </main>
      <%= if @current_scope && @current_scope.user do %>
      <.live_component
        module={CuzCoreConnectWeb.Components.SessionTimerComponent}
        id="session-timer-admin"
      />
    <% end %>
    </div>

    <!-- Overlay for mobile sidebar -->
    <div
      id="sidebar-overlay"
      class="fixed inset-0 bg-black/50 z-30 hidden lg:hidden"
      phx-click={JS.toggle(to: "#sidebar") |> JS.toggle(to: "#sidebar-overlay")}
    ></div>
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
