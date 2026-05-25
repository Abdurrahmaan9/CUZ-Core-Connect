defmodule CuzCoreConnectWeb.Student.Registration.RegistrationLive do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration
  alias CuzCoreConnectWeb.Student.Registration.Steps.Courses
  alias CuzCoreConnectWeb.Student.Registration.Steps.PersonalInfo
  alias CuzCoreConnectWeb.Student.Registration.Steps.Programmes
  alias CuzCoreConnectWeb.Student.Registration.Steps.Receipts
  alias CuzCoreConnectWeb.Student.Registration.Steps.Review
  alias CuzCoreConnectWeb.Student.Registration.Steps.Semesters

  @steps [
    :personal_info,
    :programme,
    :semester,
    :courses,
    :receipts,
    :review
  ]

  @step_labels %{
    personal_info: "Personal Info",
    programme: "Programme",
    semester: "Semester",
    courses: "Courses",
    receipts: "Receipts",
    review: "Review"
  }

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    {:ok,
     socket
     |> assign(
       current_scope: current_scope,
       current_step: :personal_info,
       show_success_modal: false,
       show_mobile_menu: false,
       tracking_number: nil,
       registration: %{
         g_number: nil,
         student_id: nil,
         student_names: nil,
         student_email: nil,
         student_contact: nil,
         program_id: nil,
         program_name: nil,
         academic_year: nil,
         semester: nil,
         intake: nil,
         courses: [],
         uploaded_receipts: []
       }
     )
     |> allow_upload(:receipt,
       accept: ~w(.jpg .jpeg .png .webp .pdf),
       auto_upload: true,
       max_entries: 3,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, steps: @steps, step_labels: @step_labels)

    ~H"""
      <Layouts.unauth flash={@flash}>
        <:header>
          <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
        </:header>
        <div class="max-w-3xl mx-auto py-8 px-4">
          <div class="mb-8">
            <h1 class="text-2xl font-bold text-gray-900">Course Registration</h1>
            <p class="text-sm text-gray-500 mt-1">
              Complete all steps to register your courses for the semester.
            </p>
          </div>

          <.step_indicator
            current_step={@current_step}
            steps={@steps}
            step_labels={@step_labels}
          />

          <div class="mt-8 bg-base-100 rounded-2xl shadow-sm border border-base-200 p-6">
            <%= case @current_step do %>
              <% :personal_info -> %>
                <.live_component module={PersonalInfo} id="step-personal-info" registration={@registration} />
              <% :programme -> %>
                <.live_component module={Programmes} id="step-programme" registration={@registration} />
              <% :semester -> %>
                <.live_component module={Semesters} id="step-semester" registration={@registration} />
              <% :courses -> %>
                <.live_component module={Courses} id="step-courses" registration={@registration} />
              <% :receipts -> %>
                <.live_component module={Receipts} id="step-receipts" registration={@registration} upload_config={@uploads.receipt} />
              <% :review -> %>
                <.live_component module={Review} id="step-review" registration={@registration} upload_config={@uploads.receipt} />
            <% end %>
          </div>
        </div>

        <%= if @show_success_modal do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div class="bg-base-100 rounded-2xl shadow-xl max-w-md w-full mx-4 p-4 sm:p-6">
              <div class="text-center">
                <div class="mx-auto flex h-12 w-12 sm:h-16 sm:w-16 items-center justify-center rounded-full bg-green-100 mb-4">
                  <.icon name="hero-check-circle" class="w-6 h-6 sm:w-8 sm:h-8 text-green-600" />
                </div>
                <h3 class="text-lg sm:text-xl font-bold text-base-content mb-2">Registration Submitted Successfully!</h3>
                <p class="text-xs sm:text-sm text-base-content/70 mb-6">
                  Your registration has been submitted for review. Please save your tracking number for future reference.
                </p>

                <div class="bg-base-200 rounded-xl p-3 sm:p-4 mb-6">
                  <p class="text-xs text-base-content/50 mb-1">Tracking Number</p>
                  <div class="flex items-center justify-center gap-2">
                    <code class="text-base sm:text-lg font-mono font-bold text-primary break-all">{@tracking_number}</code>
                    <button
                      type="button"
                      phx-click="copy_tracking_number"
                      class="p-1.5 sm:p-2 hover:bg-base-300 rounded-lg transition-colors flex-shrink-0"
                      title="Copy to clipboard"
                    >
                      <.icon name="hero-document-duplicate" class="w-4 h-4 sm:w-5 sm:h-5 text-base-content/70" />
                    </button>
                  </div>
                </div>

                <button
                  type="button"
                  phx-click="close_success_modal"
                  class="w-full btn btn-primary text-sm sm:text-base"
                >
                  Done
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </Layouts.unauth>
    """
  end

  # ── Step progress indicator ─────────────────────────────────────────────────

  defp step_indicator(assigns) do
    ~H"""
    <div class="flex items-center">
      <%= for {step, index} <- Enum.with_index(@steps) do %>
        <% current_index = Enum.find_index(@steps, &(&1 == @current_step)) %>
        <% is_current = step == @current_step %>
        <% is_complete = current_index > index %>

        <div class="flex items-center">
          <div class={[
            "w-9 h-9 rounded-full flex items-center justify-center text-sm font-semibold transition-all",
            is_complete && "bg-primary text-white",
            is_current && "bg-primary text-white ring-4 ring-primary/20",
            !is_current && !is_complete && "bg-base-200 text-base-content/40"
          ]}>
            <%= if is_complete do %>
              <.icon name="hero-check" class="w-4 h-4" />
            <% else %>
              {index + 1}
            <% end %>
          </div>
          <span class={[
            "ml-2 text-sm hidden inline",
            (is_current || is_complete) && "text-base-content",
            !is_current && !is_complete && "text-base-content/40"
          ]}>
            {@step_labels[step]}
          </span>
        </div>

        <%= if index < length(@steps) - 1 do %>
          <div class={[
            "flex-1 h-0.5 mx-4",
            is_complete && "bg-primary",
            !is_complete && "bg-base-200"
          ]} />
        <% end %>
      <% end %>
    </div>
    """
  end

  # ── Message handlers (steps communicate upward via send/2) ──────────────────

  @impl true
  def handle_info({:next_step, step_data}, socket) do
    current_step_index = Enum.find_index(@steps, &(&1 == socket.assigns.current_step))
    next_step = Enum.at(@steps, current_step_index + 1)
    registration = Map.merge(socket.assigns.registration, step_data)

    {:noreply,
     socket
     |> assign(:registration, registration)
     |> assign(:current_step, next_step)}
  end

  @impl true
  def handle_info(:prev_step, socket) do
    current_index = Enum.find_index(@steps, &(&1 == socket.assigns.current_step))
    prev_step = Enum.at(@steps, current_index - 1, socket.assigns.current_step)

    {:noreply, assign(socket, current_step: prev_step)}
  end

  @impl true
  def handle_info(:submit_registration, socket) do
    registration_data = socket.assigns.registration

    # Convert student_contact to integer as required by schema
    registration_data = case registration_data.student_contact do
      contact when is_binary(contact) ->
        Map.put(registration_data, :student_contact, String.to_integer(contact))
      _ ->
        registration_data
    end

    case Registration.create_registration(socket.assigns.current_scope, registration_data) do
      {:ok, registration} ->
        # Handle uploaded receipts
        consume_uploaded_entries(socket, :receipt, fn %{path: path}, entry ->
          Registration.create_payment_receipt(%{
            original_filename: entry.client_name,
            storage_key: path,
            content_type: entry.client_type,
            file_size: entry.client_size,
            uploaded_by_student_id: registration_data.student_id,
            student_registration_id: registration.id
          })
          {:ok, path}
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Registration submitted successfully!")
         |> assign(:show_success_modal, true)
         |> assign(:tracking_number, registration.tracking_number)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to submit registration: #{inspect(changeset.errors)}")
         |> assign(:current_step, :review)}
    end
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt, ref)}
  end

  @impl true
  def handle_event("copy_tracking_number", _params, socket) do
    {:noreply, socket |> put_flash(:info, "Tracking number copied to clipboard!")}
  end

  @impl true
  def handle_event("close_success_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_success_modal, false)
     |> push_navigate(to: "/student/registration")}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end
end
