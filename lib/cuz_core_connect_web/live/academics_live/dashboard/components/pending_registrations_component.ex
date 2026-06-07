defmodule CuzCoreConnectWeb.AcademicsLive.Dashboard.PendingRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_academics()
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations) |> assign(:selected, nil)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    registration = Registrations.get_registration!(id)

    case Registrations.update_registration(registration, %{accademics_status: "APPROVED"}) do
      {:ok, _} ->
        registrations = Registrations.list_pending_for_academics()
        {:noreply, socket |> put_flash(:info, "Registration approved.") |> assign(:registrations, registrations)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve registration.")}
    end
  end

  def handle_event("reject", %{"id" => id}, socket) do
    registration = Registrations.get_registration!(id)

    case Registrations.update_registration(registration, %{accademics_status: "REJECTED"}) do
      {:ok, _} ->
        registrations = Registrations.list_pending_for_academics()
        {:noreply, socket |> put_flash(:info, "Registration rejected.") |> assign(:registrations, registrations)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject registration.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Pending Academic Review</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <.icon name="hero-check-badge" class="h-10 w-10 mx-auto text-success mb-3" />
          <p class="font-medium">All caught up!</p>
          <p class="text-sm text-base-content/50">No registrations pending academic review.</p>
        </div>
      <% else %>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th>Student</th>
                <th>Tracking #</th>
                <th>Programme</th>
                <th>Submitted</th>
                <th>Payment</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for reg <- @registrations do %>
                <tr class="hover:bg-base-200/30">
                  <td>
                    <div class="font-medium">{reg.student_names}</div>
                    <div class="text-xs text-base-content/50">{reg.student_email}</div>
                  </td>
                  <td class="font-mono text-sm">{reg.tracking_number}</td>
                  <td>{get_in(reg.student_program_details, ["name"]) || "—"}</td>
                  <td class="text-sm">{Calendar.strftime(reg.inserted_at, "%b %d, %Y")}</td>
                  <td>
                    <span class={"badge badge-sm #{payment_badge(reg.payment_status)}"}>
                      {reg.payment_status}
                    </span>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <.button
                        phx-click="approve"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn-xs bg-success/20 text-success border-success/30"
                      >
                        Approve
                      </.button>
                      <.button
                        phx-click="reject"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn-xs bg-error/20 text-error border-error/30"
                      >
                        Reject
                      </.button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp payment_badge("APPROVED"), do: "badge-success"
  defp payment_badge("REJECTED"), do: "badge-error"
  defp payment_badge(_), do: "badge-warning"
end
