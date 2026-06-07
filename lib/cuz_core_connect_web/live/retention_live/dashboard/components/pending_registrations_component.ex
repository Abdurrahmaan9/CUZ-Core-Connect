defmodule CuzCoreConnectWeb.RetentionLive.Dashboard.PendingRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_retention()
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)

    case Registrations.update_registration(reg, %{
           retention_status: "APPROVED",
           registration_status: "APPROVED"
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Registration fully approved.")
         |> assign(:registrations, Registrations.list_pending_for_retention())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed.")}
    end
  end

  def handle_event("reject", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)

    case Registrations.update_registration(reg, %{retention_status: "REJECTED"}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rejected.")
         |> assign(:registrations, Registrations.list_pending_for_retention())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Final Retention Review</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <p class="font-medium">Nothing pending final review.</p>
        </div>
      <% else %>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th>Student</th>
                <th>Tracking #</th>
                <th>Academics</th>
                <th>Finance</th>
                <th>HOD</th>
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
                  <td><span class={"badge badge-sm #{badge(reg.accademics_status)}"}>{reg.accademics_status}</span></td>
                  <td><span class={"badge badge-sm #{badge(reg.financial_status)}"}>{reg.financial_status}</span></td>
                  <td><span class={"badge badge-sm #{badge(reg.hod_status)}"}>{reg.hod_status}</span></td>
                  <td>
                    <div class="flex gap-2">
                      <.button phx-click="approve" phx-value-id={reg.id} phx-target={@myself} class="btn-xs bg-success/20 text-success">
                        Final Approve
                      </.button>
                      <.button phx-click="reject" phx-value-id={reg.id} phx-target={@myself} class="btn-xs bg-error/20 text-error">
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

  defp badge("APPROVED"), do: "badge-success"
  defp badge("REJECTED"), do: "badge-error"
  defp badge(_), do: "badge-warning"
end
