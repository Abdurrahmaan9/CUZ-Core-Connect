defmodule CuzCoreConnectWeb.StudentLive.Dashboard.OverviewComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{current_scope: current_scope} = assigns, socket) do
    registrations =
      current_scope.user
      |> Registrations.list_registrations_by_student()
      |> Enum.reject(&CuzCoreConnect.Registrations.Registration.draft?/1)

    stats = %{
      total: length(registrations),
      approved: Enum.count(registrations, &(&1.registration_status == "APPROVED")),
      pending: Enum.count(registrations, &(&1.registration_status == "PENDING")),
      rejected: Enum.count(registrations, &(&1.registration_status == "REJECTED"))
    }

    latest = List.first(registrations)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:stats, stats)
     |> assign(:latest, latest)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6">
        <h2 class="text-xl font-semibold">
          Welcome, {extract_name(@current_scope)}
        </h2>
        <p class="text-sm text-base-content/60">Track your registration progress below</p>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <div class="bg-base-200/40 rounded-r p-4 border-l-4 border-info">
          <p class="text-xs text-base-content/60">Total Registrations</p>
          <p class="text-2xl font-bold mt-1">{@stats.total}</p>
        </div>
        <div class="bg-base-200/40 rounded-r p-4 border-l-4 border-success">
          <p class="text-xs text-base-content/60">Approved</p>
          <p class="text-2xl font-bold mt-1">{@stats.approved}</p>
        </div>
        <div class="bg-base-200/40 rounded-r p-4 border-l-4 border-warning">
          <p class="text-xs text-base-content/60">In Progress</p>
          <p class="text-2xl font-bold mt-1">{@stats.pending}</p>
        </div>
        <div class="bg-base-200/40 rounded-r p-4 border-l-4 border-error">
          <p class="text-xs text-base-content/60">Rejected</p>
          <p class="text-2xl font-bold mt-1">{@stats.rejected}</p>
        </div>
      </div>

      <%= if @latest do %>
        <div class="bg-base-200/40 rounded-r p-6 mb-6">
          <h3 class="font-medium mb-4 flex items-center gap-2">
            <.icon name="hero-document-text" class="h-5 w-5 text-primary" /> Latest Registration
          </h3>
          <div class="flex flex-wrap gap-4 items-center justify-between">
            <div>
              <p class="text-sm text-base-content/60">Tracking Number</p>
              <p class="font-mono font-medium">{@latest.tracking_number}</p>
            </div>
            <div>
              <p class="text-sm text-base-content/60">Submitted</p>
              <p class="text-sm">{Calendar.strftime(@latest.inserted_at, "%b %d, %Y")}</p>
            </div>
            <div class="flex flex-col gap-1 text-sm">
              <.stage_badge label="Payment" status={@latest.payment_status} />
              <.stage_badge label="Academics" status={@latest.accademics_status} />
              <.stage_badge label="HOD" status={@latest.hod_status} />
              <.stage_badge label="Finance" status={@latest.financial_status} />
              <.stage_badge label="Retention" status={@latest.retention_status} />
            </div>
            <span class={"badge #{overall_badge(@latest.registration_status)}"}>
              {String.capitalize(@latest.registration_status)}
            </span>
          </div>
        </div>
      <% end %>

      <div class="bg-base-200/40 rounded-r p-6">
        <h3 class="font-medium mb-3">Quick Actions</h3>
        <div class="flex flex-wrap gap-3">
          <.button phx-click="switch_tab" phx-value-tab="new_registration" phx-target={@myself}>
            <.icon name="hero-plus" class="h-4 w-4 mr-1" /> New Registration
          </.button>
          <.button phx-click="switch_tab" phx-value-tab="my_registrations" phx-target={@myself}>
            View All Registrations
          </.button>
        </div>
      </div>
    </div>
    """
  end

  defp stage_badge(assigns) do
    ~H"""
    <span class="flex items-center gap-2">
      <span class="text-base-content/60 w-20">{@label}:</span>
      <span class={"badge badge-xs #{badge_class(@status)}"}>{@status}</span>
    </span>
    """
  end

  defp badge_class("APPROVED"), do: "badge-success"
  defp badge_class("REJECTED"), do: "badge-error"
  defp badge_class(_), do: "badge-warning"

  defp overall_badge("APPROVED"), do: "badge-success"
  defp overall_badge("REJECTED"), do: "badge-error"
  defp overall_badge(_), do: "badge-warning"

  defp extract_name(%{user: %{name: name}}), do: name
  defp extract_name(_), do: "Student"
end
