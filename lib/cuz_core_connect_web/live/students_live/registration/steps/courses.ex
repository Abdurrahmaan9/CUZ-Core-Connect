defmodule CuzCoreConnectWeb.Student.Registration.Steps.Courses do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic

  @impl true
  def update(assigns, socket) do
    program_id = assigns.registration.program_id
    semester = parse_semester(assigns.registration.semester)

    available_courses =
      case {program_id, semester} do
        {pid, sem} when is_integer(pid) and is_integer(sem) ->
          Academic.list_all_courses()

        _ ->
          []
      end

    # Pre-select required (core) courses on first visit when nothing chosen yet.
    selected =
      case assigns.registration.courses do
        courses when is_list(courses) and courses != [] ->
          courses

        _ ->
          Enum.filter(available_courses, & &1.is_active)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_courses, fn -> selected end)
     |> assign(available_courses: available_courses, search: "", error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Select Courses</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Registering for:
        <span class="font-medium text-base-content/80">{@registration.program_name}</span>
        —
        <span class="font-medium text-base-content/80">
          Semester {@registration.semester}, {@registration.academic_year}
        </span>
      </p>

      <%!-- Search bar --%>
      <div class="mt-5 relative">
        <.icon
          name="hero-magnifying-glass"
          class="w-4 h-4 absolute left-3 top-3 text-base-content/40"
        />
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
              <p class="text-sm font-medium text-base-content">{course.title}</p>
              <span class="text-xs text-base-content/40">{course.credits} credit hours</span>
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

  defp total_credits(courses), do: Enum.sum(Enum.map(courses, & &1.credits))

  defp parse_semester(sem) when is_integer(sem), do: sem

  defp parse_semester(sem) when is_binary(sem) do
    case Integer.parse(sem) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_semester(_), do: nil
end
