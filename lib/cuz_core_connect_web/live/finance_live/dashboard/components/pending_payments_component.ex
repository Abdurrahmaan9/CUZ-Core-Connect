defmodule CuzCoreConnectWeb.FinanceLive.Dashboard.PendingPaymentsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{selected: :clear}, socket) do
    {:ok, assign(socket, :selected, nil)}
  end

  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_finance()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:registrations, registrations)
     |> assign_new(:selected, fn -> nil end)}
  end

  @impl true
  def handle_event("view_details", %{"id" => id}, socket) do
    registration =
      Registrations.get_registration_with_details!(id)

    {:noreply, assign(socket, :selected, registration)}
  end

  def handle_event("close_details", _, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  def handle_event("approve_payment", %{"id" => id}, socket) do
    reg = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.approve_payment(reg, actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payment verified.")
         |> assign(:registrations, Registrations.list_pending_for_finance())
         |> assign(:selected, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to verify payment.")}
    end
  end

  def handle_event("reject_payment", %{"registration_id" => id, "reason" => reason}, socket) do
    reg = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.reject_payment(reg, actor, reason) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payment rejected.")
         |> assign(:registrations, Registrations.list_pending_for_finance())
         |> assign(:selected, nil)}

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
                    <div class="flex gap-1 flex-wrap justify-end">
                      <div title="View details" class="inline-flex">
                        <button
                          type="button"
                          phx-click="view_details"
                          phx-value-id={reg.id}
                          phx-target={@myself}
                          class="btn btn-ghost btn-sm btn-square text-info hover:bg-info/10"
                          aria-label="View details"
                        >
                          <.icon name="hero-eye" class="size-5" />
                        </button>
                      </div>
                      <div title="Verify payment" class="inline-flex">
                        <button
                          type="button"
                          phx-click="approve_payment"
                          phx-value-id={reg.id}
                          phx-target={@myself}
                          class="btn btn-ghost btn-sm btn-square text-success hover:bg-success/10"
                          aria-label="Verify payment"
                        >
                          <.icon name="hero-shield-check" class="size-5" />
                        </button>
                      </div>
                      <div title="Reject payment" class="inline-flex">
                        <button
                          type="button"
                          phx-click={JS.toggle(to: "#reject-payment-form-#{reg.id}")}
                          class="btn btn-ghost btn-sm btn-square text-error hover:bg-error/10"
                          aria-label="Reject payment"
                        >
                          <.icon name="hero-x-mark" class="size-5" />
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
                <tr id={"reject-payment-form-#{reg.id}"} class="hidden">
                  <td colspan="5" class="bg-error/5">
                    <form
                      phx-submit="reject_payment"
                      phx-target={@myself}
                      class="flex gap-2 items-center py-2"
                    >
                      <input type="hidden" name="registration_id" value={reg.id} />
                      <input
                        type="text"
                        name="reason"
                        placeholder="Reason for rejecting this payment"
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

      <%= if @selected do %>
        <.live_component
          module={CuzCoreConnectWeb.RegistrationDetailsComponent}
          id="finance-registration-details-modal"
          registration={@selected}
          parent_module={__MODULE__}
          parent_id="finance-pending"
        />
      <% end %>
    </div>
    """
  end

  defp status_badge("APPROVED"), do: "badge-success"
  defp status_badge("REJECTED"), do: "badge-error"
  defp status_badge(_), do: "badge-warning"
end
