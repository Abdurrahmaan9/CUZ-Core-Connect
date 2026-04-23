defmodule CuzCoreConnectWeb.Student.Registration.Steps.Semesters do
  use CuzCoreConnectWeb, :live_component

  @semesters [
    %{value: "1", label: "Semester 1"},
    %{value: "2", label: "Semester 2"},
    %{value: "summer", label: "Summer Semester"}
  ]

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:academic_year, fn -> assigns.registration.academic_year || "" end)
     |> assign_new(:semester, fn -> assigns.registration.semester end)
     |> assign(semesters: @semesters, errors: %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Academic Year & Semester</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Specify the year and semester you are registering for.
      </p>

      <div class="mt-6 space-y-5">
        <%!-- Academic Year --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-1">
            Academic Year
          </label>
          <input
            type="text"
            value={@academic_year}
            placeholder="e.g. 2025/2026"
            phx-blur="set_year"
            phx-target={@myself}
            name="academic_year"
            class={[
              "input input-bordered w-full",
              Map.get(@errors, :academic_year) && "input-error"
            ]}
          />
          <%= if msg = Map.get(@errors, :academic_year) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>

        <%!-- Semester selector --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-2">
            Semester
          </label>
          <div class="grid grid-cols-3 gap-3">
            <%= for sem <- @semesters do %>
              <button
                type="button"
                phx-click="select_semester"
                phx-value-semester={sem.value}
                phx-target={@myself}
                class={[
                  "py-3 rounded-xl border-2 text-sm font-medium transition-all",
                  @semester == sem.value &&
                    "border-primary bg-primary/5 text-primary",
                  @semester != sem.value &&
                    "border-base-200 hover:border-base-300 text-base-content/60"
                ]}
              >
                {sem.label}
              </button>
            <% end %>
          </div>
          <%= if msg = Map.get(@errors, :semester) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>
      </div>

      <div class="mt-8 flex justify-between">
        <button
          type="button"
          phx-click="back"
          phx-target={@myself}
          class="btn btn-ghost"
        >
          ← Back
        </button>
        <button
          type="button"
          phx-click="next"
          phx-target={@myself}
          class="btn btn-primary px-8"
        >
          Next →
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("set_year", %{"value" => year}, socket) do
    {:noreply, assign(socket, academic_year: String.trim(year))}
  end

  def handle_event("select_semester", %{"semester" => semester}, socket) do
    {:noreply, assign(socket, semester: semester, errors: Map.delete(socket.assigns.errors, :semester))}
  end

  def handle_event("next", _params, socket) do
    errors = validate(socket.assigns)

    if map_size(errors) == 0 do
      send(self(), {:next_step, %{
        academic_year: socket.assigns.academic_year,
        semester: socket.assigns.semester
      }})

      {:noreply, socket}
    else
      {:noreply, assign(socket, errors: errors)}
    end
  end

  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp validate(assigns) do
    %{}
    |> maybe_add_error(:academic_year, assigns.academic_year == "", "Academic year is required.")
    |> maybe_add_error(:academic_year, not valid_year_format?(assigns.academic_year), "Use format YYYY/YYYY, e.g. 2025/2026.")
    |> maybe_add_error(:semester, is_nil(assigns.semester), "Please select a semester.")
  end

  defp maybe_add_error(errors, _key, false, _msg), do: errors
  defp maybe_add_error(errors, key, true, msg), do: Map.put(errors, key, msg)

  defp valid_year_format?(""), do: true  # handled separately above
  defp valid_year_format?(year), do: Regex.match?(~r/^\d{4}\/\d{4}$/, year)
end
