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
    <header class="fixed top-0 left-0 right-0 z-50 container mx-auto px-4 sm:px-6 lg:px-8 max-w-6xl bg-white rounded-xl shadow-sm mt-5">
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
            <span class="text-sm text-gray-600">{@current_scope.user.email}</span>
            <%= if @current_scope.user.user_role == "Admin" do %>
              <.link href={~p"/Admin/Dashboard"} class="text-sm font-medium text-primary hover:text-primary/90">Admin</.link>
            <% end %>
            <.link href={~p"/users/settings"} class="text-sm font-medium text-gray-600 hover:text-gray-900">Settings</.link>
            <.link href={~p"/users/log-out"} method="delete" class="btn btn-outline border-gray-300 text-gray-700 hover:bg-gray-50">Log out</.link>
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
