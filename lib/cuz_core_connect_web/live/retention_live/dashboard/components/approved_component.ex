defmodule CuzCoreConnectWeb.RetentionLive.Dashboard.ApprovedComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{selected: :clear}, socket) do
    {:ok, assign(socket, :selected, nil)}
  end

  def update(assigns, socket) do
    registrations = Registrations.list_by_retention_status("APPROVED")

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
      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 class="text-lg font-semibold">Completed Registrations</h2>
          <p class="text-sm text-base-content/60">
            Registrations you have given final retention approval.
          </p>
        </div>
        <span class="badge badge-success badge-outline">
          {length(@registrations)} approved
        </span>
      </div>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <.icon name="hero-check-circle" class="mx-auto mb-3 size-10 text-base-content/30" />
          <p class="font-medium text-base-content/70">No completed registrations yet.</p>
          <p class="mt-1 text-sm text-base-content/50">
            Approved items from Final Review will appear here.
          </p>
        </div>
      <% else %>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th>Student</th>
                <th>Tracking #</th>
                <th>Programme</th>
                <th>Completed</th>
                <th>Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <%= for reg <- @registrations do %>
                <tr id={"retention-approved-#{reg.id}"} class="hover:bg-base-200/30">
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
                    <span class="badge badge-sm badge-success">
                      {reg.registration_status}
                    </span>
                  </td>
                  <td class="text-right">
                    <div class="flex items-center justify-end gap-1">
                      <div title="view" class="inline-flex">
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
                      <.link
                        href={~p"/registrations/#{reg.id}/certificate"}
                        target="_blank"
                        class="btn btn-ghost btn-xs gap-1"
                        title="Proof of Registration"
                      >
                        <.icon name="hero-document-check" class="size-3.5" /> Proof
                      </.link>
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
          id="retention-approved-details-modal"
          registration={@selected}
          parent_module={__MODULE__}
          parent_id="retention-approved"
        />
      <% end %>
    </div>
    """
  end
end
