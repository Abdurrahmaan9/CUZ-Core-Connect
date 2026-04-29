defmodule CuzCoreConnectWeb.Student.Registration.Steps.Programs do
  use CuzCoreConnectWeb, :live_component

  # TODO: alias CuzCoreConnect.Academics

  @impl true
  def update(assigns, socket) do
    # TODO: replace with Academics.list_programs()
    programs = [
      %{id: 1, code: "BSCS", name: "Bachelor of Science in Computer Science"},
      %{id: 2, code: "BBA",  name: "Bachelor of Business Administration"},
      %{id: 3, code: "BE",   name: "Bachelor of Engineering"},
      %{id: 4, code: "BSIT", name: "Bachelor of Science in Information Technology"}
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_id, fn -> assigns.registration.program_id end)
     |> assign_new(:selected_name, fn -> assigns.registration.program_name end)
     |> assign(programs: programs, error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Select Your Program</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Choose the academic program you are currently enrolled in.
      </p>

      <div class="mt-6 space-y-3">
        <%= for program <- @programs do %>
          <button
            type="button"
            phx-click="select_program"
            phx-value-id={program.id}
            phx-value-name={program.name}
            phx-target={@myself}
            class={[
              "w-full text-left px-4 py-4 rounded-xl border-2 transition-all",
              @selected_id == program.id &&
                "border-primary bg-primary/5",
              @selected_id != program.id &&
                "border-base-200 hover:border-base-300"
            ]}
          >
            <span class="text-xs font-bold text-base-content/40 block mb-0.5">{program.code}</span>
            <span class={[
              "text-sm font-medium",
              @selected_id == program.id && "text-primary",
              @selected_id != program.id && "text-base-content"
            ]}>
              {program.name}
            </span>
          </button>
        <% end %>
      </div>

      <%= if @error do %>
        <p class="mt-3 text-sm text-error flex items-center gap-1">
          <.icon name="hero-exclamation-circle" class="w-4 h-4" /> {@error}
        </p>
      <% end %>

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
          Next <span aria-hidden="true">→</span>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_program", %{"id" => id, "name" => name}, socket) do
    {:noreply, assign(socket, selected_id: String.to_integer(id), selected_name: name, error: nil)}
  end

  def handle_event("next", _params, socket) do
    case socket.assigns.selected_id do
      nil ->
        {:noreply, assign(socket, error: "Please select a program to continue.")}

      _id ->
        send(self(), {:next_step, %{
          program_id: socket.assigns.selected_id,
          program_name: socket.assigns.selected_name
        }})

        {:noreply, socket}
    end
  end
end
