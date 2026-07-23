defmodule CuzCoreConnectWeb.AcademicsLive.Dashboard.PendingRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{selected: :clear}, socket) do
    {:ok, assign(socket, :selected, nil)}
  end

  def update(assigns, socket) do
    registrations = Registrations.list_pending_for_academics()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:registrations, registrations)
     |> assign_new(:selected, fn -> nil end)
     |> assign_new(:selected_ids, fn -> MapSet.new() end)}
  end

  @impl true
  def handle_event("toggle_select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_ids = socket.assigns.selected_ids

    selected_ids =
      if MapSet.member?(selected_ids, id) do
        MapSet.delete(selected_ids, id)
      else
        MapSet.put(selected_ids, id)
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  def handle_event("bulk_approve", _params, socket) do
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user
    ids = MapSet.to_list(socket.assigns.selected_ids)

    registrations =
      Enum.map(ids, &Registrations.get_registration!/1)

    {ok_count, errors} = Registrations.bulk_approve(registrations, actor, "academics")

    flash =
      if errors == [] do
        {:info, "Approved #{ok_count} registration(s)."}
      else
        {:error, "Approved #{ok_count}; #{length(errors)} failed."}
      end

    {kind, msg} = flash

    {:noreply,
     socket
     |> put_flash(kind, msg)
     |> assign(:selected_ids, MapSet.new())
     |> assign(:registrations, Registrations.list_pending_for_academics())}
  end

  def handle_event("approve", %{"id" => id}, socket) do
    registration = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.approve_academics(registration, actor) do
      {:ok, _} ->
        registrations = Registrations.list_pending_for_academics()

        {:noreply,
         socket
         |> put_flash(:info, "Registration approved.")
         |> assign(:registrations, registrations)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve registration.")}
    end
  end

  def handle_event("reject", %{"registration_id" => id, "reason" => reason}, socket) do
    registration = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.reject_academics(registration, actor, reason) do
      {:ok, _} ->
        registrations = Registrations.list_pending_for_academics()

        {:noreply,
         socket
         |> put_flash(:info, "Registration rejected.")
         |> assign(:registrations, registrations)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject registration.")}
    end
  end

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
      <h2 class="text-lg font-semibold mb-4">Pending Academic Review</h2>

      <%= if Enum.empty?(@registrations) do %>
        <div class="border-2 border-dashed border-base-300 rounded-xl p-12 text-center">
          <.icon name="hero-check-badge" class="h-10 w-10 mx-auto text-success mb-3" />
          <p class="font-medium">All caught up!</p>
          <p class="text-sm text-base-content/50">No registrations pending academic review.</p>
        </div>
      <% else %>
        <div class="flex justify-between items-center mb-3">
          <p class="text-sm text-base-content/60">
            {MapSet.size(@selected_ids)} selected
          </p>
          <.button
            phx-click="bulk_approve"
            phx-target={@myself}
            disabled={MapSet.size(@selected_ids) == 0}
            class="btn-sm bg-success text-success-content"
          >
            Approve selected
          </.button>
        </div>
        <div class="overflow-x-auto rounded-xl border border-base-300">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200/60">
                <th></th>
                <th>Student</th>
                <th>Tracking #</th>
                <th>Programme</th>
                <th>Submitted</th>
                <th>Academic</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for reg <- @registrations do %>
                <tr class="hover:bg-base-200/30">
                  <td>
                    <input
                      type="checkbox"
                      checked={MapSet.member?(@selected_ids, reg.id)}
                      phx-click="toggle_select"
                      phx-value-id={reg.id}
                      phx-target={@myself}
                      class="checkbox checkbox-sm"
                    />
                  </td>
                  <td>
                    <div class="font-medium">{reg.student_names}</div>
                    <div class="text-xs text-base-content/50">{reg.student_email}</div>
                  </td>
                  <td class="font-mono text-sm">{reg.tracking_number}</td>
                  <td>{get_in(reg.student_program_details, ["program_name"]) || "—"}</td>
                  <td class="text-sm">{Calendar.strftime(reg.inserted_at, "%b %d, %Y")}</td>
                  <td>
                    <span class={"badge badge-sm #{payment_badge(reg.accademics_status)}"}>
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
                      <div title="Approve" class="inline-flex">
                        <button
                          type="button"
                          phx-click="approve"
                          phx-value-id={reg.id}
                          phx-target={@myself}
                          class="btn btn-ghost btn-sm btn-square text-success hover:bg-success/10"
                          aria-label="Approve"
                        >
                          <.icon name="hero-check" class="size-5" />
                        </button>
                      </div>
                      <div title="Reject" class="inline-flex">
                        <button
                          type="button"
                          phx-click={JS.toggle(to: "#reject-academics-form-#{reg.id}")}
                          class="btn btn-ghost btn-sm btn-square text-error hover:bg-error/10"
                          aria-label="Reject"
                        >
                          <.icon name="hero-x-mark" class="size-5" />
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
                <tr id={"reject-academics-form-#{reg.id}"} class="hidden">
                  <td colspan="7" class="bg-error/5">
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

      <%= if @selected do %>
        <.live_component
          module={CuzCoreConnectWeb.RegistrationDetailsComponent}
          id="registration-details-modal"
          registration={@selected}
          parent_module={__MODULE__}
          parent_id="academics-pending"
        />
      <% end %>
    </div>
    """
  end

  defp payment_badge("APPROVED"), do: "badge-success"
  defp payment_badge("REJECTED"), do: "badge-error"
  defp payment_badge(_), do: "badge-warning"
end
