defmodule CuzCoreConnectWeb.FinanceLive.Dashboard.OverviewComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    stats = %{
      pending: Registrations.count_by_payment_status("PENDING"),
      verified_today: Registrations.count_approved_today_by(:payment_status),
      rejected: Registrations.count_by_payment_status("REJECTED"),
      total_verified: Registrations.count_by_payment_status("APPROVED")
    }

    {:ok, socket |> assign(assigns) |> assign(:stats, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6">
        <h2 class="text-xl font-semibold">Finance Dashboard</h2>
        <p class="text-sm text-base-content/60">Payment verification and financial review</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <.stat_card label="Pending Verification" value={@stats.pending} color="warning" icon="hero-banknotes" />
        <.stat_card label="Verified Today" value={@stats.verified_today} color="success" icon="hero-check-circle" />
        <.stat_card label="Rejected" value={@stats.rejected} color="error" icon="hero-x-circle" />
        <.stat_card label="Total Verified" value={@stats.total_verified} color="info" icon="hero-document-check" />
      </div>

      <div class="bg-base-200/40 rounded-r p-6">
        <h3 class="font-medium mb-4 flex items-center gap-2">
          <.icon name="hero-bolt" class="h-5 w-5 text-primary" />
          Quick Actions
        </h3>
        <div class="flex flex-wrap gap-3">
          <.button phx-click="switch_tab" phx-value-tab="pending" phx-target={@myself}>
            Review Pending Payments
          </.button>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class={"bg-base-200/40 rounded-r p-5 border-l-4 border-#{@color}"}>
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm text-base-content/60">{@label}</p>
          <p class="text-2xl font-bold mt-1">{@value}</p>
        </div>
        <.icon name={@icon} class={"h-8 w-8 text-#{@color} opacity-60"} />
      </div>
    </div>
    """
  end
end
