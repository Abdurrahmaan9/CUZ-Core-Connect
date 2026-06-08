defmodule CuzCoreConnectWeb.RetentionLive.Dashboard.OverviewComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    stats = %{
      pending: Registrations.count_by_retention_status("PENDING"),
      approved: Registrations.count_by_retention_status("APPROVED"),
      rejected: Registrations.count_by_retention_status("REJECTED")
    }

    {:ok, socket |> assign(assigns) |> assign(:stats, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6">
        <h2 class="text-xl font-semibold">Retention Dashboard</h2>
        <p class="text-sm text-base-content/60">Final stage registration review</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        <div class="bg-base-200/40 rounded-r p-5 border-l-4 border-warning">
          <p class="text-sm text-base-content/60">Awaiting Final Review</p>
          <p class="text-2xl font-bold mt-1">{@stats.pending}</p>
        </div>
        <div class="bg-base-200/40 rounded-r p-5 border-l-4 border-success">
          <p class="text-sm text-base-content/60">Fully Approved</p>
          <p class="text-2xl font-bold mt-1">{@stats.approved}</p>
        </div>
        <div class="bg-base-200/40 rounded-r p-5 border-l-4 border-error">
          <p class="text-sm text-base-content/60">Rejected</p>
          <p class="text-2xl font-bold mt-1">{@stats.rejected}</p>
        </div>
      </div>

      <div class="bg-base-200/40 rounded-r p-6">
        <h3 class="font-medium mb-3">Quick Actions</h3>
        <.button phx-click="switch_tab" phx-value-tab="pending" phx-target={@myself}>
          Begin Final Reviews
        </.button>
      </div>
    </div>
    """
  end
end
