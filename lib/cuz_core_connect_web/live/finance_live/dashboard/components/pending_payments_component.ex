defmodule CuzCoreConnectWeb.FinanceLive.Dashboard.PendingPaymentsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_finance()
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations)}
  end

  @impl true
  def handle_event("approve_payment", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)

    case Registrations.update_registration(reg, %{payment_status: "APPROVED", financial_status: "APPROVED"}) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Payment verified.") |> assign(:registrations, Registrations.list_pending_for_finance())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to verify payment.")}
    end
  end

  def handle_event("reject_payment", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)

    case Registrations.update_registration(reg, %{payment_status: "REJECTED", financial_status: "REJECTED"}) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Payment rejected.") |> assign(:registrations, Registrations.list_pending_for_finance())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject payment.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">Pending Payment Verification</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <.icon name="hero-check-badge" class="h-10 w-10 mx-auto text-success mb-3" />
          <p class="font-medium">All payments verified!</p>
          <p class="text-sm text-base-content/50">No payments pending review.</p>
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
                    <span class={"badge badge-sm #{status_badge(reg.accademics_status)}"}>
                      {reg.accademics_status}
                    </span>
                  </td>
                  <td>
                    <div class="flex gap-2">
                      <.button
                        phx-click="approve_payment"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn-xs bg-success/20 text-success"
                      >
                        Verify
                      </.button>
                      <.button
                        phx-click="reject_payment"
                        phx-value-id={reg.id}
                        phx-target={@myself}
                        class="btn-xs bg-error/20 text-error"
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

  defp status_badge("APPROVED"), do: "badge-success"
  defp status_badge("REJECTED"), do: "badge-error"
  defp status_badge(_), do: "badge-warning"
end
