defmodule CuzCoreConnectWeb.Student.Registration.Steps.Courses do
  use CuzCoreConnectWeb, :live_component

  # TODO: alias CuzCoreConnect.Academics

  @impl true
  def update(assigns, socket) do
    # TODO: Replace with Academics.list_courses_for(program_id, semester)
    # using assigns.registration.program_id and assigns.registration.semester
    available_courses = [
      %{id: 1, code: "CS101", name: "Introduction to Programming",      credit_hours: 3},
      %{id: 2, code: "CS201", name: "Data Structures & Algorithms",     credit_hours: 3},
      %{id: 3, code: "CS301", name: "Database Systems",                  credit_hours: 3},
      %{id: 4, code: "CS401", name: "Software Engineering",             credit_hours: 3},
      %{id: 5, code: "MA101", name: "Calculus I",                       credit_hours: 4},
      %{id: 6, code: "MA201", name: "Linear Algebra",                   credit_hours: 3},
      %{id: 7, code: "EN101", name: "Technical Writing",                credit_hours: 2},
      %{id: 8, code: "CS501", name: "Operating Systems",                credit_hours: 3}
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_courses, fn -> assigns.registration.courses end)
     |> assign(available_courses: available_courses, search: "", error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Select Courses</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Registering for: <span class="font-medium text-base-content/80">{@registration.program_name}</span>
        — <span class="font-medium text-base-content/80">
          Semester {@registration.semester}, {@registration.academic_year}
        </span>
      </p>

      <%!-- Search bar --%>
      <div class="mt-5 relative">
        <.icon name="hero-magnifying-glass" class="w-4 h-4 absolute left-3 top-3 text-base-content/40" />
        <input
          type="text"
          value={@search}
          placeholder="Search courses..."
          phx-input="search"
          phx-target={@myself}
          name="search"
          class="input input-bordered w-full pl-9"
        />
      </div>

      <%!-- Available courses --%>
      <div class="mt-4 space-y-2 max-h-72 overflow-y-auto pr-1">
        <%= for course <- filtered_courses(@available_courses, @search) do %>
          <% is_selected = Enum.any?(@selected_courses, &(&1.id == course.id)) %>
          <div class={[
            "flex items-center justify-between px-4 py-3 rounded-xl border transition-all",
            is_selected && "border-primary/30 bg-primary/5",
            !is_selected && "border-base-200 bg-base-100"
          ]}>
            <div>
              <span class="text-xs font-bold text-base-content/40">{course.code}</span>
              <p class="text-sm font-medium text-base-content">{course.name}</p>
              <span class="text-xs text-base-content/40">{course.credit_hours} credit hours</span>
            </div>
            <button
              type="button"
              phx-click={if is_selected, do: "remove_course", else: "add_course"}
              phx-value-id={course.id}
              phx-target={@myself}
              class={[
                "btn btn-sm",
                is_selected && "btn-error btn-outline",
                !is_selected && "btn-primary btn-outline"
              ]}
            >
              <%= if is_selected do %>
                <.icon name="hero-minus" class="w-4 h-4" /> Remove
              <% else %>
                <.icon name="hero-plus" class="w-4 h-4" /> Add
              <% end %>
            </button>
          </div>
        <% end %>
      </div>

      <%!-- Selected summary --%>
      <div class="mt-5 p-4 bg-base-200 rounded-xl">
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-base-content/80">
            Selected: {length(@selected_courses)} course(s)
          </span>
          <span class="text-sm font-medium text-base-content/80">
            Total credits: {total_credits(@selected_courses)}
          </span>
        </div>
      </div>

      <%= if @error do %>
        <p class="mt-2 text-sm text-error flex items-center gap-1">
          <.icon name="hero-exclamation-circle" class="w-4 h-4" /> {@error}
        </p>
      <% end %>

      <div class="mt-6 flex justify-between">
        <button type="button" phx-click="back" phx-target={@myself} class="btn btn-ghost">
          ← Back
        </button>
        <button type="button" phx-click="next" phx-target={@myself} class="btn btn-primary px-8">
          Review →
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    {:noreply, assign(socket, search: query)}
  end

  def handle_event("add_course", %{"id" => id}, socket) do
    course = Enum.find(socket.assigns.available_courses, &(&1.id == String.to_integer(id)))
    updated = [course | socket.assigns.selected_courses]

    {:noreply, assign(socket, selected_courses: updated, error: nil)}
  end

  def handle_event("remove_course", %{"id" => id}, socket) do
    updated = Enum.reject(socket.assigns.selected_courses, &(&1.id == String.to_integer(id)))

    {:noreply, assign(socket, selected_courses: updated)}
  end

  def handle_event("next", _params, socket) do
    if socket.assigns.selected_courses == [] do
      {:noreply, assign(socket, error: "Please add at least one course to continue.")}
    else
      send(self(), {:next_step, %{courses: socket.assigns.selected_courses}})
      {:noreply, socket}
    end
  end

  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp filtered_courses(courses, ""), do: courses
  defp filtered_courses(courses, query) do
    q = String.downcase(query)
    Enum.filter(courses, fn c ->
      String.contains?(String.downcase(c.name), q) or
      String.contains?(String.downcase(c.code), q)
    end)
  end

  defp total_credits(courses), do: Enum.sum(Enum.map(courses, & &1.credit_hours))
end
