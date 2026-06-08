defmodule CuzCoreConnectWeb.RegistrationDetailsComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("close", _, socket) do
    send(self(), {:close_details, nil})
    {:noreply, socket}
  end

  def handle_event("click_modal", _, socket) do
    # Prevent closing when clicking inside the modal
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black/50 z-40 flex items-center justify-center" phx-click="close" phx-target={@myself}>
      <div
        class="bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto"
        phx-click="click_modal"
        phx-target={@myself}
      >
        <%!-- Header --%>
        <div class="sticky top-0 bg-gradient-to-r from-base-200 to-base-100 px-6 py-4 border-b border-base-300 flex items-center justify-between">
          <div>
            <h2 class="text-2xl font-bold">{@registration.student_names}</h2>
            <p class="text-sm text-base-content/60 mt-1">Tracking #{@registration.tracking_number}</p>
          </div>
          <button
            phx-click="close"
            phx-target={@myself}
            class="btn btn-ghost btn-circle btn-sm"
            aria-label="Close"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Content --%>
        <div class="p-6 space-y-6">
          <%!-- Personal Information --%>
          <section class="space-y-4">
            <h3 class="text-lg font-semibold border-b border-base-300 pb-3">Personal Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="text-sm font-medium text-base-content/70">Student ID</p>
                <p class="text-base font-mono">{@registration.student_id}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Email</p>
                <p class="text-base break-all">{@registration.student_email}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Contact</p>
                <p class="text-base font-mono">{@registration.student_contact}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Submitted</p>
                <p class="text-base">{Calendar.strftime(@registration.inserted_at, "%b %d, %Y at %H:%M")}</p>
              </div>
            </div>
          </section>

          <%!-- Program Information --%>
          <section class="space-y-4">
            <h3 class="text-lg font-semibold border-b border-base-300 pb-3">Program Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="text-sm font-medium text-base-content/70">Program</p>
                <p class="text-base">{get_in(@registration.student_program_details, ["program_name"]) || "—"}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Academic Year</p>
                <p class="text-base">{get_in(@registration.student_program_details, ["academic_year"]) || "—"}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Semester</p>
                <p class="text-base">{get_in(@registration.student_program_details, ["semester"]) || "—"}</p>
              </div>
              <div>
                <p class="text-sm font-medium text-base-content/70">Intake</p>
                <p class="text-base">{get_in(@registration.student_program_details, ["intake"]) || "—"}</p>
              </div>
            </div>
          </section>

          <%!-- Courses --%>
          <%= if get_in(@registration.student_courses, ["selected_courses"]) do %>
            <section class="space-y-4">
              <h3 class="text-lg font-semibold border-b border-base-300 pb-3">Registered Courses</h3>
              <div class="space-y-2">
                <%= for course <- get_in(@registration.student_courses, ["selected_courses"]) do %>
                  <div class="flex items-start gap-3 p-3 bg-base-100 rounded-lg">
                    <div class="flex-1">
                      <p class="font-mono font-medium text-sm">{course["code"]}</p>
                      <p class="text-sm text-base-content/70">{course["name"]}</p>
                    </div>
                    <%= if course["credit_hours"] do %>
                      <div class="text-right">
                        <p class="text-xs font-medium text-base-content/60">Credits</p>
                        <p class="font-semibold">{course["credit_hours"]}</p>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </section>
          <% end %>

          <%!-- Payment Receipts --%>
          <%= if @registration.payment_receipts != [] do %>
            <section class="space-y-4">
              <h3 class="text-lg font-semibold border-b border-base-300 pb-3">Payment Receipts</h3>
              <div class="space-y-3">
                <%= for receipt <- @registration.payment_receipts do %>
                  <div class="border border-base-300 rounded-lg overflow-hidden">
                    <%!-- Image preview --%>
                    <%= if String.starts_with?(receipt.content_type, "image/") do %>
                      <img
                        src={~p"/receipts/#{receipt.id}"}
                        alt={receipt.original_filename}
                        class="w-full max-h-96 object-contain bg-base-200"
                      />
                    <% end %>
                    <%!-- File info bar --%>
                    <div class="flex items-center gap-3 p-3 bg-base-100">
                      <.icon name="hero-document" class="w-5 h-5 text-base-content/50 shrink-0" />
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium truncate">{receipt.original_filename}</p>
                        <p class="text-xs text-base-content/50">
                          {receipt.content_type} · {format_file_size(receipt.file_size)}
                        </p>
                      </div>
                      <p class="text-xs text-base-content/40 shrink-0">
                        {Calendar.strftime(receipt.inserted_at, "%b %d, %Y")}
                      </p>
                    </div>
                  </div>
                <% end %>
              </div>
            </section>
          <% end %>

          <%!-- Approval Status --%>
          <section class="space-y-4">
            <h3 class="text-lg font-semibold border-b border-base-300 pb-3">Approval Status</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">Payment</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.payment_status)}"}>
                    {@registration.payment_status}
                  </span>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">Academic</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.accademics_status)}"}>
                    {@registration.accademics_status}
                  </span>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">HOD</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.hod_status)}"}>
                    {@registration.hod_status}
                  </span>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">Retention</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.retention_status)}"}>
                    {@registration.retention_status}
                  </span>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">Financial</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.financial_status)}"}>
                    {@registration.financial_status}
                  </span>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div class="flex-1">
                  <p class="text-sm font-medium text-base-content/70">Registration</p>
                  <span class={"badge badge-sm #{status_badge_color(@registration.registration_status)}"}>
                    {@registration.registration_status}
                  </span>
                </div>
              </div>
            </div>
          </section>
        </div>

        <%!-- Footer --%>
        <div class="bg-base-100 px-6 py-4 border-t border-base-300 flex justify-end gap-2">
          <button
            phx-click="close"
            phx-target={@myself}
            class="btn btn-outline btn-sm"
          >
            Close
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge_color("APPROVED"), do: "badge-success"
  defp status_badge_color("REJECTED"), do: "badge-error"
  defp status_badge_color("PENDING"), do: "badge-warning"
  defp status_badge_color(_), do: "badge-info"

  defp has_receipts?(%{payment_receipts: receipts}) do
    is_list(receipts) && Enum.any?(receipts)
  end
  defp has_receipts?(_), do: false

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_file_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"
end
