defmodule CuzCoreConnectWeb.Student.Registration.Steps.PersonalInfo do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:student_id, fn -> assigns.registration.student_id || "" end)
     |> assign_new(:student_names, fn -> assigns.registration.student_names || "" end)
     |> assign_new(:student_email, fn -> assigns.registration.student_email || "" end)
     |> assign_new(:student_contact, fn -> assigns.registration.student_contact || "" end)
     |> assign(errors: %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Personal Information</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Please provide your personal details for registration.
      </p>

      <div class="mt-6 space-y-5">
        <%!-- Student ID --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-1">
            Student ID
          </label>
          <input
            type="text"
            value={@student_id}
            placeholder="e.g. 202512345"
            phx-blur="set_student_id"
            phx-target={@myself}
            name="student_id"
            class={[
              "input input-bordered w-full",
              Map.get(@errors, :student_id) && "input-error"
            ]}
          />
          <%= if msg = Map.get(@errors, :student_id) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>

        <%!-- Full Name --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-1">
            Full Name
          </label>
          <input
            type="text"
            value={@student_names}
            placeholder="e.g. Abdur-rahmaan"
            phx-blur="set_student_names"
            phx-target={@myself}
            name="student_names"
            class={[
              "input input-bordered w-full",
              Map.get(@errors, :student_names) && "input-error"
            ]}
          />
          <%= if msg = Map.get(@errors, :student_names) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>

        <%!-- Email --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-1">
            Email Address
          </label>
          <input
            type="email"
            value={@student_email}
            placeholder="e.g. ac100000@cavendish.students.co.zm"
            phx-blur="set_student_email"
            phx-target={@myself}
            name="student_email"
            class={[
              "input input-bordered w-full",
              Map.get(@errors, :student_email) && "input-error"
            ]}
          />
          <%= if msg = Map.get(@errors, :student_email) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>

        <%!-- Contact Number --%>
        <div>
          <label class="block text-sm font-medium text-base-content/80 mb-1">
            Contact Number
          </label>
          <input
            type="tel"
            value={@student_contact}
            placeholder="e.g. +1234567890"
            phx-blur="set_student_contact"
            phx-target={@myself}
            name="student_contact"
            class={[
              "input input-bordered w-full",
              Map.get(@errors, :student_contact) && "input-error"
            ]}
          />
          <%= if msg = Map.get(@errors, :student_contact) do %>
            <p class="mt-1 text-xs text-error">{msg}</p>
          <% end %>
        </div>
      </div>

      <%= if Enum.any?(@errors) do %>
        <div class="mt-4 p-3 bg-error/10 border border-error/200 rounded-lg">
          <p class="text-sm text-error font-medium">Please correct the errors above before continuing.</p>
        </div>
      <% end %>

      <div class="mt-8 flex justify-end">
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
  def handle_event("set_student_id", %{"value" => student_id}, socket) do
    {:noreply, assign(socket, student_id: String.trim(student_id))}
  end

  def handle_event("set_student_names", %{"value" => student_names}, socket) do
    {:noreply, assign(socket, student_names: String.trim(student_names))}
  end

  def handle_event("set_student_email", %{"value" => student_email}, socket) do
    {:noreply, assign(socket, student_email: String.trim(student_email))}
  end

  def handle_event("set_student_contact", %{"value" => student_contact}, socket) do
    {:noreply, assign(socket, student_contact: String.trim(student_contact))}
  end

  def handle_event("next", _params, socket) do
    errors = validate(socket.assigns)

    if map_size(errors) == 0 do
      send(self(), {:next_step, %{
        student_id: socket.assigns.student_id,
        student_names: socket.assigns.student_names,
        student_email: socket.assigns.student_email,
        student_contact: socket.assigns.student_contact
      }})

      {:noreply, socket}
    else
      {:noreply, assign(socket, errors: errors)}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp validate(assigns) do
    %{}
    |> maybe_add_error(:student_id, assigns.student_id == "", "Student ID is required.")
    |> maybe_add_error(:student_id, not valid_student_id_format?(assigns.student_id), "Student ID should be numeric and at least 6 digits.")
    |> maybe_add_error(:student_names, assigns.student_names == "", "Full name is required.")
    |> maybe_add_error(:student_names, String.length(assigns.student_names) < 3, "Name must be at least 3 characters.")
    |> maybe_add_error(:student_email, assigns.student_email == "", "Email address is required.")
    |> maybe_add_error(:student_email, not valid_email_format?(assigns.student_email), "Please enter a valid email address.")
    |> maybe_add_error(:student_contact, assigns.student_contact == "", "Contact number is required.")
    |> maybe_add_error(:student_contact, not valid_contact_format?(assigns.student_contact), "Please enter a valid contact number.")
  end

  defp maybe_add_error(errors, _key, false, _msg), do: errors
  defp maybe_add_error(errors, key, true, msg), do: Map.put(errors, key, msg)

  defp valid_student_id_format?(""), do: false
  defp valid_student_id_format?(student_id) do
    Regex.match?(~r/^\d{6,}$/, student_id)
  end

  defp valid_email_format?(""), do: false
  defp valid_email_format?(email) do
    Regex.match?(~r/^[^\s]+@[^\s]+\.[^\s]+$/, email)
  end

  defp valid_contact_format?(""), do: false
  defp valid_contact_format?(contact) do
    # Basic validation for phone numbers with optional + prefix
    Regex.match?(~r/^\+?\d{7,}$/, String.replace(contact, ~r/\s/, ""))
  end
end
