defmodule CuzCoreConnectWeb.StudentLive.Dashboard.MyRegistrationsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Registrations

  @impl true
  def update(%{current_scope: current_scope} = assigns, socket) do
    registrations = Registrations.list_registrations_by_student(current_scope.user.id)
    {:ok, socket |> assign(assigns) |> assign(:registrations, registrations)}
  end

  @impl true
  def handle_event("resubmit", %{"id" => id}, socket) do
    registration = Registrations.get_registration!(id)
    actor = socket.assigns.current_scope && socket.assigns.current_scope.user

    case Registrations.resubmit_registration(registration, actor) do
      {:ok, _} ->
        registrations =
          Registrations.list_registrations_by_student(socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Registration resubmitted for review.")
         |> assign(:registrations, registrations)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to resubmit this registration.")}
    end
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

              <%= if reg.registration_status == "REJECTED" do %>
                <div class="mt-4 p-3 rounded-lg bg-error/10 border border-error/20 flex flex-wrap items-center justify-between gap-3">
                  <p class="text-sm text-error">
                    Rejected at <strong>{String.capitalize(reg.rejected_stage || "a stage")}</strong>: {reg.rejection_reason ||
                      "No reason provided."}
                  </p>
                  <.button
                    phx-click="resubmit"
                    phx-value-id={reg.id}
                    phx-target={@myself}
                    data-confirm="Resubmit this registration for review?"
                    class="btn-xs bg-primary text-primary-content"
                  >
                    Revise &amp; Resubmit
                  </.button>
                </div>
              <% end %>

              <%= if reg.registration_status == "APPROVED" do %>
                <div class="mt-4 flex justify-end">
                  <.link
                    href={~p"/registration/tracking/#{reg.tracking_number}/proof"}
                    target="_blank"
                    class="btn btn-sm bg-indigo-600 text-white hover:bg-indigo-700"
                  >
                    <.icon name="hero-document-check" class="w-4 h-4" /> Proof of Registration
                  </.link>
                </div>
              <% end %>
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
