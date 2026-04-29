defmodule CuzCoreConnectWeb.Student.Registration.RegistrationLive do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration
  alias CuzCoreConnectWeb.Student.Registration.Steps.Courses
  alias CuzCoreConnectWeb.Student.Registration.Steps.PersonalInfo
  alias CuzCoreConnectWeb.Student.Registration.Steps.Programs
  alias CuzCoreConnectWeb.Student.Registration.Steps.Receipts
  alias CuzCoreConnectWeb.Student.Registration.Steps.Review
  alias CuzCoreConnectWeb.Student.Registration.Steps.Semesters

  @steps [
    :personal_info,
    :program,
    :semester,
    :courses,
    :receipts,
    :review
  ]

  @step_labels %{
    personal_info: "Personal Info",
    program: "Program",
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
       registration: %{
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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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
            <% :program -> %>
              <.live_component module={Programs} id="step-program" registration={@registration} />
            <% :semester -> %>
              <.live_component module={Semesters} id="step-semester" registration={@registration} />
            <% :courses -> %>
              <.live_component module={Courses} id="step-courses" registration={@registration} />
            <% :receipts -> %>
              <.live_component
                module={Receipts}
                id="step-receipts"
                upload_config={@uploads.receipt}
              />
            <% :review -> %>
              <.live_component module={Review} id="step-review" registration={@registration} upload_config={@uploads.receipt} />
          <% end %>
        </div>
      </div>
    </Layouts.app>
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
            "ml-2 text-sm font-medium hidden sm:inline",
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

  def handle_info(:prev_step, socket) do
    current_index = Enum.find_index(@steps, &(&1 == socket.assigns.current_step))
    prev_step = Enum.at(@steps, current_index - 1, socket.assigns.current_step)

    {:noreply, assign(socket, current_step: prev_step)}
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
  def handle_event("next_receipt_step", _params, socket) do
    {completed_entries, in_progress_entries} = uploaded_entries(socket, :receipt)

    cond do
      in_progress_entries != [] ->
        {:noreply, put_flash(socket, :error, "Please wait for the receipt upload to finish before continuing.")}

      completed_entries == [] ->
        {:noreply, put_flash(socket, :error, "At least one payment receipt is required to continue.")}

      true ->
        current_step_index = Enum.find_index(@steps, &(&1 == socket.assigns.current_step))
        next_step = Enum.at(@steps, current_step_index + 1)

        {:noreply, assign(socket, :current_step, next_step)}
    end
  end

  @impl true
  def handle_event("submit_review", _params, socket) do
    {completed_entries, in_progress_entries} = uploaded_entries(socket, :receipt)

    cond do
      in_progress_entries != [] ->
        {:noreply, put_flash(socket, :error, "Please wait for the receipt upload to finish before submitting.")}

      completed_entries == [] ->
        {:noreply, put_flash(socket, :error, "At least one payment receipt is required to submit registration.")}

      true ->
        handle_submit_registration(socket.assigns.registration, socket)
    end
  end


  defp handle_submit_registration(reg, socket) do
    # Process uploads from parent's upload config
    uploaded_files =
      consume_uploaded_entries(socket, :receipt, fn %{path: tmp_path}, entry ->
        # Build a unique storage key
        ext = Path.extname(entry.client_name)
        key = "receipts/#{Date.utc_today().year}/#{Ecto.UUID.generate()}#{ext}"

        # Save to priv/static/uploads directory
        uploads_dir = "priv/static/uploads"
        dest = Path.join([uploads_dir, key])
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(tmp_path, dest)

        {:ok, %{
          original_filename: entry.client_name,
          storage_key: key,
          content_type: entry.client_type,
          file_size: entry.client_size
        }}
      end)

    # Add uploaded files to registration data
    reg_with_receipts = Map.put(reg, :uploaded_receipts, uploaded_files)

    with {:ok, registration} <- Registration.create_registration(nil, reg_with_receipts) do
      case save_receipts(registration.id, uploaded_files) do
        :ok ->
          {:noreply,
           socket
           |> put_flash(:info, "Registration submitted! Tracking #: #{registration.tracking_number}")
           |> push_navigate(to: "/")}

        _ ->
          {:noreply, put_flash(socket, :error, "Receipt saving failed, please try again.")}
      end
    else
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Submission failed, please try again.")}
    end
  end

  defp save_receipts(_registration_id, nil), do: {:error, "No payment receipts provided"}
  defp save_receipts(_registration_id, []), do: {:error, "At least one payment receipt is required"}

  defp save_receipts(registration_id, files) do
    results =
      Enum.map(files, fn file ->
        Registration.create_payment_receipt(%{
          student_registration_id: registration_id,
          uploaded_by_student_id: nil,
          original_filename: file.original_filename,
          storage_key: file.storage_key,
          content_type: file.content_type,
          file_size: file.file_size
        })
      end)

    if Enum.any?(results, fn result -> result == :error or match?({:error, _}, result) end) do
      {:error, "Failed to save some payment receipts"}
    else
      :ok
    end
  end
end
