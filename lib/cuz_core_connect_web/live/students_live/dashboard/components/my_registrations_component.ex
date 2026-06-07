defmodule CuzCoreConnectWeb.StudentLive.Dashboard.MyRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{current_scope: current_scope} = assigns, socket) do
    registrations = Registrations.list_registrations_by_student(current_scope.user.id)
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">My Registrations</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <.icon name="hero-document-plus" class="h-10 w-10 mx-auto text-base-content/30 mb-3" />
          <p class="font-medium">No registrations yet</p>
          <p class="text-sm text-base-content/50 mt-1">Start a new registration to get enrolled.</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for reg <- @registrations do %>
            <div class="bg-base-200/40 rounded-xl p-5 border border-base-300">
              <div class="flex flex-wrap justify-between items-start gap-4">
                <div>
                  <p class="font-mono font-medium text-sm">{reg.tracking_number}</p>
                  <p class="text-xs text-base-content/50 mt-1">
                    Submitted {Calendar.strftime(reg.inserted_at, "%B %d, %Y")}
                  </p>
                </div>
                <span class={"badge #{overall_badge(reg.registration_status)}"}>
                  {String.capitalize(reg.registration_status)}
                </span>
              </div>

              <div class="mt-4 grid grid-cols-2 sm:grid-cols-5 gap-2">
                <%= for {label, status} <- [
                  {"Payment", reg.payment_status},
                  {"Academics", reg.accademics_status},
                  {"HOD", reg.hod_status},
                  {"Finance", reg.financial_status},
                  {"Retention", reg.retention_status}
                ] do %>
                  <div class="text-center">
                    <p class="text-xs text-base-content/50 mb-1">{label}</p>
                    <span class={"badge badge-sm w-full #{badge_class(status)}"}>{status}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp badge_class("APPROVED"), do: "badge-success"
  defp badge_class("REJECTED"), do: "badge-error"
  defp badge_class(_), do: "badge-warning"

  defp overall_badge("APPROVED"), do: "badge-success"
  defp overall_badge("REJECTED"), do: "badge-error"
  defp overall_badge(_), do: "badge-warning"
end
