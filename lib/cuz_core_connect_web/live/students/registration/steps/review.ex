defmodule CuzCoreConnectWeb.Student.Registration.Steps.Review do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:registration, assigns.registration)
     |> assign(:id, assigns.id)
     |> assign(:upload_config, assigns.upload_config)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Review Your Registration</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Please confirm all details before submitting.
      </p>

      <%!-- Summary cards --%>
      <div class="mt-6 space-y-4">

        <%!-- Program --%>
        <.review_row label="Program" value={@registration.program_name} />

        <%!-- Semester --%>
        <.review_row
          label="Semester"
          value={"Semester #{@registration.semester}, Academic Year #{@registration.academic_year}, Intake #{@registration.intake}"}
        />

        <%!-- Courses --%>
        <div class="flex gap-4 py-3 border-b border-base-200">
          <span class="w-32 shrink-0 text-sm font-medium text-base-content/70">Courses</span>
          <div class="flex-1 space-y-2">
            <%= for course <- @registration.courses do %>
              <div class="flex justify-between text-sm">
                <span class="text-base-content">
                  <span class="font-mono text-xs text-base-content/40 mr-2">{course.code}</span>
                  {course.name}
                </span>
                <span class="text-base-content/60 shrink-0 ml-4">{course.credit_hours} cr</span>
              </div>
            <% end %>

            <div class="pt-2 border-t border-base-200 flex justify-between text-sm font-semibold">
              <span class="text-base-content/80">Total Credit Hours</span>
              <span class="text-primary">
                {Enum.sum(Enum.map(@registration.courses, & &1.credit_hours))}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <div class="flex items-center justify-between border-b border-base-200 py-3">
          <span class="text-sm font-medium text-base-content/70">Attached Receipts</span>
          <span class="rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
            {length(@upload_config.entries)} file(s)
          </span>
        </div>

        <div class="mt-3 space-y-2">
          <%= for entry <- @upload_config.entries do %>
            <div class="flex items-center justify-between rounded-xl border border-base-200 bg-base-100 px-4 py-3">
              <div class="flex items-center gap-2 min-w-0">
                <.icon name="hero-paper-clip" class="w-4 h-4 text-base-content/50" />
                <span class="truncate text-sm text-base-content">{entry.client_name}</span>
              </div>
              <span class="text-xs font-medium text-green-600">
                <%= if entry.done?, do: "Ready", else: "#{entry.progress}% uploaded" %>
              </span>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-8 flex justify-between">
        <button type="button" phx-click="back" phx-target={@myself} class="btn btn-ghost">
          ← Back
        </button>
        <button type="button" phx-click="submit_review" class="btn btn-primary px-8">
          <.icon name="hero-check-circle" class="w-5 h-5 mr-1" /> Submit Registration
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp review_row(assigns) do
    ~H"""
    <div class="flex gap-4 py-3 border-b border-base-200">
      <span class="w-32 shrink-0 text-sm font-medium text-base-content/70">{@label}</span>
      <span class="text-sm text-base-content">{@value}</span>
    </div>
    """
  end
end
