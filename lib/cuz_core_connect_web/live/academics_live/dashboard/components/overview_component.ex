defmodule CuzCoreConnectWeb.AcademicsLive.Dashboard.OverviewComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    stats = %{
      pending: Registrations.count_by_academics_status("PENDING"),
      approved_today: Registrations.count_approved_today_by(:accademics_status),
      rejected: Registrations.count_by_academics_status("REJECTED"),
      total_reviewed: Registrations.count_by_academics_status("APPROVED")
    }

    {:ok, socket |> assign(assigns) |> assign(:stats, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6">
        <h2 class="text-xl font-semibold">Welcome back, {extract_name(@current_scope)}</h2>
        <p class="text-sm text-base-content/60">Here's your academic review summary</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <.stat_card label="Pending Review" value={@stats.pending} color="warning" icon="hero-clock" />
        <.stat_card
          label="Approved Today"
          value={@stats.approved_today}
          color="success"
          icon="hero-check-circle"
        />
        <.stat_card label="Rejected" value={@stats.rejected} color="error" icon="hero-x-circle" />
        <.stat_card
          label="Total Reviewed"
          value={@stats.total_reviewed}
          color="info"
          icon="hero-academic-cap"
        />
      </div>

      <div class="bg-base-200/40 rounded-xl p-6">
        <h3 class="font-medium mb-4 flex items-center gap-2">
          <.icon name="hero-clipboard-document-list" class="h-5 w-5 text-primary" /> Quick Actions
        </h3>
        <div class="flex flex-wrap gap-3">
          <.button phx-click="switch_tab" phx-value-tab="pending" phx-target={@myself}>
            Review Pending Registrations
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

  defp extract_name(%{user: %{name: name}}), do: name
  defp extract_name(_), do: "Officer"
end
