defmodule CuzCoreConnectWeb.HODLive.Dashboard.ApprovedComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{selected: :clear}, socket) do
    {:ok, assign(socket, :selected, nil)}
  end

  def update(assigns, socket) do
    registrations = Registrations.list_by_hod_status("APPROVED")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:registrations, registrations)
     |> assign_new(:selected, fn -> nil end)}
  end

  @impl true
  def handle_event("view_details", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected, Registrations.get_registration_with_details!(id))}
  end

  def handle_event("close_details", _, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">HOD Approved Registrations</h2>
      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <p class="text-base-content/50">No HOD-approved registrations yet.</p>
        </div>
      <% else %>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th>Student</th>
                <th>Tracking #</th>
                <th>Programme</th>
                <th>Approved At</th>
                <th>Overall Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <%= for reg <- @registrations do %>
                <tr id={"hod-approved-#{reg.id}"} class="hover:bg-base-200/30">
                  <td>
                    <div class="font-medium">{reg.student_names}</div>
                    <div class="text-xs text-base-content/50">{reg.student_email}</div>
                  </td>
                  <td class="font-mono text-sm">{reg.tracking_number}</td>
                  <td class="text-sm">
                    {get_in(reg.student_program_details, ["program_name"]) || "—"}
                  </td>
                  <td class="text-sm">{Calendar.strftime(reg.updated_at, "%b %d, %Y")}</td>
                  <td>
                    <span class={"badge badge-sm #{status_badge(reg.registration_status)}"}>
                      {reg.registration_status}
                    </span>
                  </td>
                  <td class="text-right">
                    <div title="View" class="inline-flex">
                      <button
                        type="button"
                        phx-click="view_details"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn btn-ghost btn-sm btn-square text-info hover:bg-info/10"
                        aria-label="View"
                      >
                        <.icon name="hero-eye" class="size-5" />
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>

      <%= if @selected do %>
        <.live_component
          module={CuzCoreConnectWeb.RegistrationDetailsComponent}
          id="hod-approved-details-modal"
          registration={@selected}
          parent_module={__MODULE__}
          parent_id="hod-approved"
        />
      <% end %>
    </div>
    """
  end

  defp status_badge("APPROVED"), do: "badge-success"
  defp status_badge("PENDING"), do: "badge-warning"
  defp status_badge(_), do: "badge-neutral"
end
