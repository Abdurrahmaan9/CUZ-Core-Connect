defmodule CuzCoreConnectWeb.Student.Registration.RegistrationLive do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Registrations
  alias CuzCoreConnect.Registrations.Registration
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
    authenticated? = match?(%{user: %{id: _}}, current_scope)

    socket =
      socket
      |> assign(
        current_scope: current_scope,
        authenticated?: authenticated?,
        page_title: "Course Registration",
        current_page: :student_new_registration,
        current_step: :personal_info,
        show_success_modal: false,
        show_mobile_menu: false,
        tracking_number: nil,
        draft: nil,
        drafts: [],
        view_mode: if(authenticated?, do: :drafts_list, else: :wizard),
        registration: blank_registration()
      )
      |> allow_upload(:receipt,
        accept: ~w(.jpg .jpeg .png .webp .pdf),
        auto_upload: true,
        max_entries: 3,
        max_file_size: 5_000_000
      )

    socket =
      if authenticated? do
        assign(socket, :drafts, Registrations.list_drafts_for_student(current_scope.user))
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"draft_id" => draft_id}, _uri, socket) do
    case Registrations.get_registration(String.to_integer(draft_id)) do
      %Registration{registration_status: "DRAFT"} = draft ->
        allowed? =
          if socket.assigns.authenticated? do
            Registrations.owns_registration?(socket.assigns.current_scope.user, draft)
          else
            true
          end

        if allowed? do
          {:noreply, load_draft_into_wizard(socket, draft)}
        else
          {:noreply, put_flash(socket, :error, "Draft not found.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Draft not found.")}
    end
  rescue
    ArgumentError ->
      {:noreply, put_flash(socket, :error, "Invalid draft.")}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, steps: @steps, step_labels: @step_labels)

    ~H"""
    <%= if @authenticated? do %>
      <Layouts.user
        flash={@flash}
        current_scope={@current_scope}
        page_title={@page_title}
        current_page={@current_page}
      >
        <.registration_body {assigns} />
      </Layouts.user>
    <% else %>
      <Layouts.unauth flash={@flash} current_scope={@current_scope}>
        <:header>
          <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
        </:header>
        <.registration_body {assigns} />
        <:footer>
          <CuzCoreConnectWeb.Navigations.Unauth.footer />
        </:footer>
      </Layouts.unauth>
    <% end %>
    """
  end

  defp registration_body(assigns) do
    ~H"""
    <div class={[
      "mx-auto px-4 sm:px-6",
      @authenticated? && "py-2",
      !@authenticated? && "max-w-3xl py-8"
    ]}>
      <%= if @authenticated? and @view_mode == :drafts_list do %>
        <.drafts_list drafts={@drafts} />
      <% else %>
        <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold text-base-content">Course Registration</h1>
            <p class="text-sm text-base-content/60 mt-1">
              Complete all steps, then submit to send your registration into the approval workflow.
            </p>
          </div>
          <button
            :if={@authenticated?}
            type="button"
            phx-click="back_to_drafts"
            class="btn btn-ghost btn-sm"
          >
            ← My drafts
          </button>
        </div>

        <.step_indicator current_step={@current_step} steps={@steps} step_labels={@step_labels} />

        <div class="mt-8 bg-base-100 rounded-2xl shadow-sm border border-base-300 p-6">
          <% wizard_key = (@draft && @draft.id) || "new" %>
          <%= case @current_step do %>
            <% :personal_info -> %>
              <.live_component
                module={PersonalInfo}
                id={"step-personal-info-#{wizard_key}"}
                registration={@registration}
                authenticated?={@authenticated?}
              />
            <% :programme -> %>
              <.live_component
                module={Programmes}
                id={"step-programme-#{wizard_key}"}
                registration={@registration}
                authenticated?={@authenticated?}
              />
            <% :semester -> %>
              <.live_component
                module={Semesters}
                id={"step-semester-#{wizard_key}"}
                registration={@registration}
                authenticated?={@authenticated?}
              />
            <% :courses -> %>
              <.live_component
                module={Courses}
                id={"step-courses-#{wizard_key}-#{@registration.program_id}"}
                registration={@registration}
                authenticated?={@authenticated?}
              />
            <% :receipts -> %>
              <.live_component
                module={Receipts}
                id={"step-receipts-#{wizard_key}"}
                registration={@registration}
                upload_config={@uploads.receipt}
                authenticated?={@authenticated?}
              />
            <% :review -> %>
              <.live_component
                module={Review}
                id={"step-review-#{wizard_key}"}
                registration={@registration}
                upload_config={@uploads.receipt}
                authenticated?={@authenticated?}
              />
          <% end %>
        </div>
      <% end %>

      <%= if @show_success_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div class="bg-base-100 rounded-2xl shadow-xl max-w-md w-full p-6">
            <div class="text-center">
              <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-success/15">
                <.icon name="hero-check-circle" class="w-8 h-8 text-success" />
              </div>
              <h3 class="text-xl font-bold mb-2">Registration Submitted</h3>
              <p class="text-sm text-base-content/70 mb-6">
                Your registration is now in the approval workflow. Save your tracking number.
              </p>
              <div class="bg-base-200 rounded-xl p-4 mb-6">
                <p class="text-xs text-base-content/50 mb-1">Tracking Number</p>
                <div class="flex items-center">
                  <div class="flex-1 flex justify-center">
                    <code class="text-lg font-mono font-bold text-primary break-all text-center">
                      {@tracking_number}
                    </code>
                  </div>
                  <div class="ml-2 flex-shrink-0">
                    <.copy_button id="tracking-number" value={@tracking_number}/>
                  </div>
                </div>

                <button type="button" phx-click="close_success_modal" class="btn btn-primary w-full">
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp drafts_list(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 class="text-2xl font-bold text-base-content">Course Registration</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Continue an unfinished registration or start a new one.
          </p>
        </div>
        <button type="button" phx-click="start_new" class="btn btn-primary">
          <.icon name="hero-plus" class="size-4" /> Start new registration
        </button>
      </div>

      <div class="overflow-x-auto rounded-box border border-base-300 bg-base-100 shadow-sm">
        <table class="table">
          <thead>
            <tr>
              <th>Student</th>
              <th>Programme</th>
              <th>Step</th>
              <th>Updated</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={draft <- @drafts} id={"draft-#{draft.id}"} class="hover">
              <td>
                <div class="font-medium">{draft.student_names}</div>
                <div class="text-xs text-base-content/50 font-mono">{draft.student_id}</div>
              </td>
              <td class="text-sm">
                {get_in(draft.student_program_details, ["program_name"]) ||
                  get_in(draft.student_program_details, [:program_name]) || "—"}
              </td>
              <td>
                <span class="badge badge-sm badge-warning badge-outline capitalize">
                  {String.replace(draft.wizard_step || "personal_info", "_", " ")}
                </span>
              </td>
              <td class="text-sm text-base-content/70">
                {Calendar.strftime(draft.updated_at, "%b %d, %Y")}
              </td>
              <td class="text-right">
                <div class="flex justify-end gap-2">
                  <button
                    type="button"
                    phx-click="continue_draft"
                    phx-value-id={draft.id}
                    class="btn btn-primary btn-sm"
                  >
                    Continue
                  </button>
                  <button
                    type="button"
                    phx-click="delete_draft"
                    phx-value-id={draft.id}
                    data-confirm="Delete this unfinished registration?"
                    class="btn btn-ghost btn-sm text-error"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
            <tr :if={@drafts == []}>
              <td colspan="5" class="py-10 text-center text-base-content/50">
                No unfinished registrations. Start a new one to begin.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp step_indicator(assigns) do
    ~H"""
    <div class="flex items-center overflow-x-auto pb-2">
      <%= for {step, index} <- Enum.with_index(@steps) do %>
        <% current_index = Enum.find_index(@steps, &(&1 == @current_step)) %>
        <% is_current = step == @current_step %>
        <% is_complete = current_index > index %>
        <div class="flex items-center shrink-0">
          <div class={[
            "w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold",
            (is_complete or is_current) && "bg-primary text-primary-content",
            !is_current && !is_complete && "bg-base-200 text-base-content/40"
          ]}>
            <%= if is_complete do %>
              <.icon name="hero-check" class="w-4 h-4" />
            <% else %>
              {index + 1}
            <% end %>
          </div>
          <span class={[
            "ml-2 text-xs sm:text-sm mr-2",
            (is_current or is_complete) && "text-base-content",
            !is_current && !is_complete && "text-base-content/40"
          ]}>
            {@step_labels[step]}
          </span>
        </div>
        <div
          :if={index < length(@steps) - 1}
          class={[
            "flex-1 h-0.5 mx-2 min-w-4",
            is_complete && "bg-primary",
            !is_complete && "bg-base-200"
          ]}
        />
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:next_step, step_data}, socket) do
    current_step = socket.assigns.current_step
    current_index = Enum.find_index(@steps, &(&1 == current_step))
    next_step = Enum.at(@steps, current_index + 1, current_step)

    registration =
      socket.assigns.registration
      |> Map.merge(step_data)
      |> maybe_reset_courses_for_program_change(socket.assigns.registration, step_data)

    socket =
      socket
      |> assign(:registration, registration)
      |> persist_draft(next_step)

    if current_step == :personal_info and is_nil(socket.assigns.draft) do
      {:noreply, put_flash(socket, :error, "Could not save your details. Please try again.")}
    else
      {:noreply, assign(socket, :current_step, next_step)}
    end
  end

  def handle_info({:save_step, step_data}, socket) do
    registration = Map.merge(socket.assigns.registration, step_data)

    socket =
      socket
      |> assign(:registration, registration)
      |> persist_draft(socket.assigns.current_step)

    socket =
      if socket.assigns.draft do
        put_flash(socket, :info, "Progress saved.")
      else
        put_flash(socket, :error, "Could not save progress.")
      end

    {:noreply, socket}
  end

  def handle_info(:prev_step, socket) do
    current_index = Enum.find_index(@steps, &(&1 == socket.assigns.current_step))
    prev_step = Enum.at(@steps, current_index - 1, socket.assigns.current_step)
    {:noreply, assign(socket, current_step: prev_step)}
  end

  def handle_info(:submit_registration, socket) do
    registration_data = socket.assigns.registration

    case Registrations.create_registration(socket.assigns.current_scope, registration_data,
           draft: socket.assigns.draft
         ) do
      {:ok, registration} ->
        _ = maybe_ensure_student_account(registration_data, socket.assigns.current_scope)

        results =
          consume_uploaded_entries(socket, :receipt, fn %{path: path}, entry ->
            case Registrations.persist_payment_receipt(registration, path, %{
                   client_name: entry.client_name,
                   client_type: entry.client_type,
                   client_size: entry.client_size,
                   uploaded_by_student_id: registration_data.student_id
                 }) do
              {:ok, receipt} -> {:ok, receipt.storage_key}
              {:error, reason} -> {:postpone, {:error, reason}}
            end
          end)

        failed? =
          Enum.any?(List.wrap(results), fn
            {:error, _} -> true
            _ -> false
          end)

        socket =
          if failed? do
            put_flash(
              socket,
              :error,
              "Registration submitted, but a receipt failed to store. Contact support with your tracking number."
            )
          else
            put_flash(socket, :info, "Registration submitted successfully!")
          end

        {:noreply,
         socket
         |> assign(:show_success_modal, true)
         |> assign(:tracking_number, registration.tracking_number)
         |> assign(:draft, nil)
         |> push_patch(to: ~p"/student/registrations/new")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to submit: #{inspect(changeset.errors)}")
         |> assign(:current_step, :review)}
    end
  end

  @impl true
  def handle_event("start_new", _params, socket) do
    {:noreply,
     socket
     |> assign(:view_mode, :wizard)
     |> assign(:draft, nil)
     |> assign(:current_step, :personal_info)
     |> assign(:registration, registration_from_scope(socket.assigns.current_scope))
     |> push_patch(to: ~p"/student/registrations/new")}
  end

  def handle_event("back_to_drafts", _params, socket) do
    drafts = Registrations.list_drafts_for_student(socket.assigns.current_scope.user)

    {:noreply,
     socket
     |> assign(:drafts, drafts)
     |> assign(:view_mode, :drafts_list)
     |> assign(:draft, nil)
     |> assign(:registration, blank_registration())
     |> push_patch(to: ~p"/student/registrations/new")}
  end

  def handle_event("continue_draft", %{"id" => id}, socket) do
    draft = Registrations.get_registration!(id)

    if Registrations.owns_registration?(socket.assigns.current_scope.user, draft) and
         Registration.draft?(draft) do
      {:noreply,
       socket
       |> load_draft_into_wizard(draft)
       |> push_patch(to: ~p"/student/registrations/new?draft_id=#{draft.id}")}
    else
      {:noreply, put_flash(socket, :error, "Draft not found.")}
    end
  end

  def handle_event("delete_draft", %{"id" => id}, socket) do
    draft = Registrations.get_registration!(id)

    if Registrations.owns_registration?(socket.assigns.current_scope.user, draft) do
      _ = Registrations.delete_draft(draft)
      drafts = Registrations.list_drafts_for_student(socket.assigns.current_scope.user)

      {:noreply,
       socket
       |> assign(:drafts, drafts)
       |> put_flash(:info, "Draft deleted.")}
    else
      {:noreply, put_flash(socket, :error, "Could not delete draft.")}
    end
  end

  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt, ref)}
  end

  def handle_event("copy_tracking_number", _params, socket) do
    {:noreply, put_flash(socket, :info, "Tracking number copied to clipboard!")}
  end

  def handle_event("close_success_modal", _params, socket) do
    path =
      if socket.assigns.authenticated? do
        ~p"/student/dashboard?tab=my_registrations"
      else
        ~p"/registration/tracking/#{socket.assigns.tracking_number}"
      end

    {:noreply,
     socket
     |> assign(:show_success_modal, false)
     |> push_navigate(to: path)}
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  defp load_draft_into_wizard(socket, draft) do
    step =
      case draft.wizard_step do
        step when is_binary(step) ->
          String.to_existing_atom(step)

        _ ->
          :personal_info
      end

    step = if step in @steps, do: step, else: :personal_info

    socket
    |> assign(:view_mode, :wizard)
    |> assign(:draft, draft)
    |> assign(:registration, Registrations.to_wizard_map(draft))
    |> assign(:current_step, step)
  rescue
    ArgumentError ->
      socket
      |> assign(:view_mode, :wizard)
      |> assign(:draft, draft)
      |> assign(:registration, Registrations.to_wizard_map(draft))
      |> assign(:current_step, :personal_info)
  end

  defp persist_draft(socket, wizard_step) do
    # Persist once personal info is present (first meaningful save).
    reg = socket.assigns.registration

    if blank?(reg.student_id) or blank?(reg.student_names) or blank?(reg.student_email) or
         blank?(reg.student_contact) do
      socket
    else
      case Registrations.save_draft(reg, socket.assigns.draft, wizard_step: wizard_step) do
        {:ok, draft} ->
          socket
          |> assign(:draft, draft)
          |> maybe_patch_draft_url(draft)

        {:error, _} ->
          socket
      end
    end
  end

  defp maybe_patch_draft_url(socket, draft) do
    path =
      if socket.assigns.authenticated? do
        ~p"/student/registrations/new?draft_id=#{draft.id}"
      else
        ~p"/student/registration?draft_id=#{draft.id}"
      end

    push_patch(socket, to: path)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  defp blank_registration do
    %{
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
  end

  defp maybe_reset_courses_for_program_change(registration, previous, %{
         program_id: new_program_id
       }) do
    if previous.program_id != new_program_id do
      Map.put(registration, :courses, [])
    else
      registration
    end
  end

  defp maybe_reset_courses_for_program_change(registration, _previous, _step_data),
    do: registration

  defp registration_from_scope(%{user: user}) when not is_nil(user) do
    names =
      [user.first_name, user.middle_name, user.last_name]
      |> Enum.reject(&(is_nil(&1) or &1 == ""))
      |> Enum.join(" ")

    %{
      blank_registration()
      | student_id: user.student_number,
        student_names: if(names == "", do: nil, else: names),
        student_email: user.email
    }
  end

  defp registration_from_scope(_), do: blank_registration()

  defp maybe_ensure_student_account(registration_data, current_scope) do
    if current_scope && Map.get(current_scope, :user) do
      :ok
    else
      case Accounts.ensure_student_account(%{
             student_id: registration_data.student_id,
             student_names: registration_data.student_names,
             student_email: registration_data.student_email,
             email: registration_data.student_email
           }) do
        {:ok, _, _} ->
          :ok

        {:error, reason} ->
          require Logger
          Logger.warning("Could not ensure student account: #{inspect(reason)}")
          :error
      end
    end
  end
end
