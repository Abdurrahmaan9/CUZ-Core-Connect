defmodule CuzCoreConnectWeb.Student.Registration.Steps.Programmes do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic

  @impl true
  def update(assigns, socket) do
    programmes = Academic.list_active_programs()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_id, fn -> assigns.registration.program_id end)
     |> assign_new(:selected_name, fn -> assigns.registration.program_name end)
     |> assign(programmes: programmes, error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Select Your Programme</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Choose the academic programme you are currently enrolled in.
      </p>

      <%= if Enum.empty?(@programmes) do %>
        <div class="mt-6 border-2 border-dashed border-base-300 rounded-xl p-8 text-center">
          <p class="font-medium">No programmes available yet</p>
          <p class="text-sm text-base-content/50 mt-1">
            Ask an administrator to create an active programme first.
          </p>
        </div>
      <% else %>
        <div class="mt-6 space-y-3">
          <%= for programme <- @programmes do %>
            <button
              type="button"
              phx-click="select_program"
              phx-value-id={programme.id}
              phx-value-name={programme.name}
              phx-target={@myself}
              class={[
                "w-full text-left px-4 py-3 rounded-xl border transition-all",
                @selected_id == programme.id && "border-primary bg-primary/5",
                @selected_id != programme.id && "border-base-200 hover:border-base-300"
              ]}
            >
              <span class="text-xs font-bold text-base-content/40">{programme.code}</span>
              <p class="text-sm font-medium text-base-content">{programme.name}</p>
            </button>
          <% end %>
        </div>
      <% end %>

      <%= if @error do %>
        <p class="mt-2 text-sm text-error flex items-center gap-1">
          <.icon name="hero-exclamation-circle" class="w-4 h-4" /> {@error}
        </p>
      <% end %>

      <div class="mt-8 flex justify-end">
        <button type="button" phx-click="next" phx-target={@myself} class="btn btn-primary px-8">
          Next <span aria-hidden="true">→</span>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_program", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     assign(socket, selected_id: String.to_integer(id), selected_name: name, error: nil)}
  end

  def handle_event("next", _params, socket) do
    if is_nil(socket.assigns.selected_id) do
      {:noreply, assign(socket, error: "Please select a programme to continue.")}
    else
      send(
        self(),
        {:next_step,
         %{
           program_id: socket.assigns.selected_id,
           program_name: socket.assigns.selected_name
         }}
      )

      {:noreply, socket}
    end
  end
end
