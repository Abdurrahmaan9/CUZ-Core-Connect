defmodule CuzCoreConnectWeb.HODLive.Dashboard.PendingRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_hod()
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.approve_hod(reg, actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Approved.")
         |> assign(:registrations, Registrations.list_pending_for_hod())}

      {:error, :stage_not_ready} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Cannot approve: Academics and Payment must be approved first."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed.")}
    end
  end

  def handle_event("reject", %{"registration_id" => id, "reason" => reason}, socket) do
    reg = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.reject_hod(reg, actor, reason) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rejected.")
         |> assign(:registrations, Registrations.list_pending_for_hod())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Pending HOD Review</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <p class="font-medium">Nothing pending.</p>
        </div>
      <% else %>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th>Student</th>
                <th>Tracking #</th>
                <th>Submitted</th>
                <th>Academics</th>
                <th>Finance</th>
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
                  <td class="text-sm">{Calendar.strftime(reg.inserted_at, "%b %d, %Y")}</td>
                  <td>
                    <span class={"badge badge-sm #{badge(reg.accademics_status)}"}>
                      {reg.accademics_status}
                    </span>
                  </td>
                  <td>
                    <span class={"badge badge-sm #{badge(reg.financial_status)}"}>
                      {reg.financial_status}
                    </span>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <.button
                        phx-click="approve"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn-xs bg-success/20 text-success"
                      >
                        Approve
                      </.button>
                      <.button
                        phx-click={JS.toggle(to: "#reject-hod-form-#{reg.id}")}
                        class="btn-xs bg-error/20 text-error"
                      >
                        Reject
                      </.button>
                    </div>
                  </td>
                </tr>
                <tr id={"reject-hod-form-#{reg.id}"} class="hidden">
                  <td colspan="6" class="bg-error/5">
                    <form
                      phx-submit="reject"
                      phx-target={@myself}
                      class="flex gap-2 items-center py-2"
                    >
                      <input type="hidden" name="registration_id" value={reg.id} />
                      <input
                        type="text"
                        name="reason"
                        placeholder="Reason for rejection"
                        required
                        class="input input-bordered input-sm flex-1"
                      />
                      <button type="submit" class="btn btn-sm bg-error text-white">
                        Confirm Reject
                      </button>
                    </form>
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
