defmodule CuzCoreConnectWeb.LandingLive do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:count, 0)
     |> assign(:subtitle, "This page is powered by Phoenix LiveView, updating instantly without a page reload.")}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="mx-auto max-w-3xl rounded-[2rem] border border-base-200 bg-base-100/80 p-8 shadow-xl shadow-base-200/40">
        <div class="space-y-6">
          <div class="rounded-3xl bg-base-200 p-6">
            <p class="text-sm uppercase tracking-[0.32em] text-base-content/60">LiveView in action</p>
            <h1 class="mt-4 text-4xl font-semibold tracking-tight text-base-content">Live View Demo</h1>
            <p class="mt-3 max-w-2xl leading-7 text-base-content/75">{@subtitle}</p>
          </div>

          <div class="grid gap-6 sm:grid-cols-[1.2fr_auto]">
            <div class="rounded-3xl border border-base-200 bg-base-200 p-6">
              <p class="text-sm uppercase tracking-[0.28em] text-base-content/60">Current count</p>
              <p class="mt-4 text-7xl font-bold leading-none">{@count}</p>
              <p class="mt-3 text-sm text-base-content/70">Click the button to update this number without a page reload.</p>
            </div>

            <div class="flex items-center rounded-3xl border border-base-200 bg-white p-6 shadow-sm">
              <button
                type="button"
                phx-click="increment"
                class="btn btn-primary btn-lg w-full"
              >
                Increment
              </button>
            </div>
          </div>

          <div class="rounded-3xl border border-base-200 bg-base-200 p-6 text-base-content/80">
            <p class="text-sm font-semibold text-base-content">Why LiveView?</p>
            <ul class="mt-4 space-y-2 text-sm leading-6">
              <li>• Updates page state instantly from the server.</li>
              <li>• No manual client-side JavaScript required.</li>
              <li>• Ideal for fast feedback loops and interactive prototypes.</li>
            </ul>
          </div>
        </div>
      </div>
    """
  end
end
