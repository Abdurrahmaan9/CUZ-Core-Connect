defmodule CuzCoreConnectWeb.Components.SessionTimerComponent do
  use CuzCoreConnectWeb, :live_component

  @inactivity_threshold_ms 3 * 60 * 1000
  @countdown_seconds 60
  @tick_interval_ms 1000

  def mount(socket) do
    {:ok,
     socket
     |> assign(:show_timer, false)
     |> assign(:inactivity_threshold_ms, @inactivity_threshold_ms)
     |> assign(:countdown, @countdown_seconds)
     |> assign(:tick_ref, nil)}
  end

  def handle_event("user_activity", _params, socket) do
    socket = cancel_tick(socket)
    {:noreply, assign(socket, show_timer: false, countdown: @countdown_seconds)}
  end

  def handle_event("inactivity_detected", _params, socket) do
    socket = cancel_tick(socket)
    tick_ref = schedule_tick()

    {:noreply,
     socket
     |> assign(:show_timer, true)
     |> assign(:countdown, @countdown_seconds)
     |> assign(:tick_ref, tick_ref)}
  end

  def handle_event("stay_logged_in", _params, socket) do
    socket = cancel_tick(socket)

    {:noreply,
     socket
     |> assign(:show_timer, false)
     |> assign(:countdown, @countdown_seconds)
     |> push_event("reset_inactivity_timer", %{})}
  end

  def handle_event("session_logout", _params, socket) do
    {:noreply, redirect(socket, to: "/user-accounts/log-out")}
  end

  def handle_event("logout_now", _params, socket) do
    {:noreply, redirect(socket, to: "/user-accounts/log-out")}
  end

  def handle_event("tick", %{"seconds_left" => seconds}, socket) do
    {:noreply, assign(socket, countdown: seconds)}
  end



  def handle_info(:tick, %{assigns: %{countdown: 1}} = socket) do
    {:noreply,
     socket
     |> assign(:countdown, 0)
     |> push_event("session_expired", %{})}
  end

  def handle_info(:tick, %{assigns: %{countdown: countdown}} = socket) do
    tick_ref = schedule_tick()

    {:noreply,
     socket
     |> assign(:countdown, countdown - 1)
     |> assign(:tick_ref, tick_ref)}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval_ms)
  end

  defp cancel_tick(%{assigns: %{tick_ref: nil}} = socket), do: socket

  defp cancel_tick(%{assigns: %{tick_ref: ref}} = socket) do
    Process.cancel_timer(ref)
    assign(socket, :tick_ref, nil)
  end

  def render(assigns) do
    ~H"""
    <div
      id="session-timer-component"
      phx-hook="SessionTimer"
      data-inactivity-ms={@inactivity_threshold_ms}
      data-target={@myself}
    >
      <%= if @show_timer do %>
        <div class="session-timer-overlay" role="dialog" aria-modal="true" aria-label="Session timeout warning">
          <div class="session-timer-modal">
            <div class="session-timer-header">
              <div class="session-timer-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <polyline points="12 6 12 12 16 14"/>
                </svg>
              </div>
              <span>Session Timeout</span>
            </div>

            <p class="session-timer-message">
              Your session is about to expire due to inactivity. You will be logged out in
            </p>

            <div class="session-timer-ring-wrapper">
              <svg class="session-timer-ring" viewBox="0 0 120 120" width="140" height="140">
                <circle
                  class="session-timer-ring-bg"
                  cx="60" cy="60" r="52"
                  fill="none"
                  stroke-width="4"
                  stroke-dasharray="4 4"
                />
                <circle
                  class="session-timer-ring-progress"
                  cx="60" cy="60" r="52"
                  fill="none"
                  stroke-width="5"
                  stroke-linecap="round"
                  stroke-dasharray={"#{Float.round(@countdown / 60 * 326.7, 1)} 326.7"}
                  stroke-dashoffset="81.7"
                  transform="rotate(-90 60 60)"
                />
                <text x="60" y="56" text-anchor="middle" class="session-timer-count">
                  <%= @countdown %>
                </text>
                <text x="60" y="72" text-anchor="middle" class="session-timer-label">
                  seconds
                </text>
              </svg>
            </div>

            <div class="session-timer-actions">
              <button
                phx-click="stay_logged_in"
                phx-target={@myself}
                class="session-timer-btn-primary"
              >
                Stay Logged In
              </button>
              <button
                phx-click="session_logout"
                phx-target={@myself}
                class="session-timer-btn-secondary"
              >
                Log Out Now
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

end
