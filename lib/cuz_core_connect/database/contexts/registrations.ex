defmodule CuzCoreConnect.Registrations do
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Registrations.Registration
  alias CuzCoreConnect.Students.PaymentReceipt
  alias CuzCoreConnect.Approvals.MemoApproval
  import Ecto.Query

  @pagination [page_size: 10]

  def list_pending_for_academics do
    Repo.all(
      from r in Registration,
        where:
          r.accademics_status == "PENDING" and
            r.registration_status == "PENDING" and
            is_nil(r.deleted_at),
        order_by: [asc: r.inserted_at]
    )
  end

  def count_pending_registrations do
    from(r in Registration,
      where: r.registration_status == "PENDING" and is_nil(r.deleted_at),
      select: count(r.id)
    )
    |> Repo.one()
  end

  def list_pending_for_finance do
    Repo.all(
      from r in Registration,
        where:
          r.payment_status == "PENDING" and
            r.registration_status == "PENDING" and
            is_nil(r.deleted_at),
        order_by: [asc: r.inserted_at]
    )
  end

  def list_pending_for_hod do
    Repo.all(
      from r in Registration,
        where:
          r.hod_status == "PENDING" and
            r.registration_status == "PENDING" and
            r.accademics_status == "APPROVED" and
            r.payment_status == "APPROVED" and
            is_nil(r.deleted_at),
        order_by: [asc: r.inserted_at]
    )
  end

  def list_pending_for_retention do
    Repo.all(
      from r in Registration,
        where:
          r.retention_status == "PENDING" and
            r.registration_status == "PENDING" and
            r.hod_status == "APPROVED" and
            r.accademics_status == "APPROVED" and
            r.payment_status == "APPROVED" and
            is_nil(r.deleted_at),
        order_by: [asc: r.inserted_at]
    )
  end

  def list_registrations_by_student(%CuzCoreConnect.Accounts.User{} = user) do
    student_number =
      case user.student_number do
        number when is_binary(number) and number != "" -> number
        _ -> nil
      end

    email =
      case user.email do
        address when is_binary(address) and address != "" -> String.downcase(address)
        _ -> nil
      end

    user_id = to_string(user.id)

    conditions = dynamic([r], r.student_id == ^user_id)

    conditions =
      if student_number do
        dynamic([r], ^conditions or r.student_id == ^student_number)
      else
        conditions
      end

    conditions =
      if email do
        dynamic([r], ^conditions or fragment("lower(?)", r.student_email) == ^email)
      else
        conditions
      end

    from(r in Registration,
      where: is_nil(r.deleted_at),
      where: ^conditions,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  def list_registrations_by_student(user_id) when is_integer(user_id) do
    case CuzCoreConnect.Repo.get(CuzCoreConnect.Accounts.User, user_id) do
      %CuzCoreConnect.Accounts.User{} = user ->
        list_registrations_by_student(user)

      nil ->
        Repo.all(
          from r in Registration,
            where: r.student_id == ^to_string(user_id) and is_nil(r.deleted_at),
            order_by: [desc: r.inserted_at]
        )
    end
  end

  def list_registrations_by_student(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {id, ""} ->
        list_registrations_by_student(id)

      _ ->
        Repo.all(
          from r in Registration,
            where: r.student_id == ^user_id and is_nil(r.deleted_at),
            order_by: [desc: r.inserted_at]
        )
    end
  end

  @doc """
  Returns true when the user owns the registration (student number, email, or legacy user id).
  """
  def owns_registration?(%CuzCoreConnect.Accounts.User{} = user, %Registration{} = registration) do
    student_number = user.student_number && to_string(user.student_number)
    user_email = String.downcase(to_string(user.email || ""))
    reg_student_id = to_string(registration.student_id || "")
    reg_email = String.downcase(to_string(registration.student_email || ""))

    (is_binary(student_number) and student_number != "" and student_number == reg_student_id) or
      to_string(user.id) == reg_student_id or
      (user_email != "" and user_email == reg_email)
  end

  def owns_registration?(_, _), do: false

  @doc """
  Incomplete wizard entries for a student (not yet in the approval workflow).
  """
  def list_drafts_for_student(%CuzCoreConnect.Accounts.User{} = user) do
    user
    |> list_registrations_by_student()
    |> Enum.filter(&Registration.draft?/1)
  end

  def list_submitted_for_student(%CuzCoreConnect.Accounts.User{} = user) do
    user
    |> list_registrations_by_student()
    |> Enum.reject(&Registration.draft?/1)
  end

  @doc """
  Saves wizard progress as a DRAFT. Creates or updates. Does not enter workflow.
  """
  def save_draft(registration_data, existing \\ nil, opts \\ []) do
    wizard_step = Keyword.get(opts, :wizard_step)
    attrs = build_draft_attrs(registration_data, wizard_step)

    case existing do
      %Registration{registration_status: "DRAFT"} = draft ->
        draft
        |> Registration.draft_changeset(attrs)
        |> Repo.update()

      nil ->
        %Registration{}
        |> Registration.draft_changeset(attrs)
        |> Repo.insert()

      %Registration{} ->
        {:error, :not_a_draft}
    end
  end

  def delete_draft(%Registration{registration_status: "DRAFT"} = draft) do
    Repo.delete(draft)
  end

  def delete_draft(_), do: {:error, :not_a_draft}

  @doc """
  Converts a persisted registration into the LiveView wizard map.
  """
  def to_wizard_map(%Registration{} = registration) do
    details = stringify_keys(registration.student_program_details || %{})
    courses_map = registration.student_courses || %{}

    courses =
      case courses_map do
        %{"selected_courses" => items} when is_list(items) -> Enum.map(items, &course_from_map/1)
        %{selected_courses: items} when is_list(items) -> Enum.map(items, &course_from_map/1)
        %{"items" => items} when is_list(items) -> Enum.map(items, &course_from_map/1)
        list when is_list(list) -> Enum.map(list, &course_from_map/1)
        _ -> []
      end

    %{
      student_id: registration.student_id,
      student_names: registration.student_names,
      student_email: registration.student_email,
      student_contact: contact_to_string(registration.student_contact),
      program_id: parse_int(details["program_id"]),
      program_name: details["program_name"],
      academic_year: details["academic_year"],
      semester: details["semester"],
      intake: details["intake"],
      courses: courses,
      uploaded_receipts: [],
      g_number: nil
    }
  end

  defp course_from_map(course) when is_map(course) do
    course = stringify_keys(course)

    %{
      id: parse_int(course["id"]),
      code: course["code"],
      title: course["title"] || course["name"],
      name: course["name"] || course["title"],
      credits: parse_int(course["credits"]) || 0
    }
  end

  defp course_from_map(_), do: %{id: nil, code: "", title: "", name: "", credits: 0}

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {to_string(k), v}
    end)
  end

  defp stringify_keys(_), do: %{}

  defp parse_int(nil), do: nil
  defp parse_int(value) when is_integer(value), do: value

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_int(_), do: nil

  defp contact_to_string(nil), do: ""
  defp contact_to_string(contact) when is_integer(contact), do: Integer.to_string(contact)
  defp contact_to_string(contact), do: to_string(contact)

  defp build_draft_attrs(registration_data, wizard_step) do
    data = normalize_wizard_data(registration_data)

    %{
      student_id: data.student_id,
      student_names: data.student_names,
      student_email: data.student_email,
      student_contact: data.student_contact,
      student_program_details: %{
        "program_id" => data.program_id,
        "program_name" => data.program_name,
        "academic_year" => data.academic_year,
        "semester" => data.semester,
        "intake" => data.intake
      },
      student_courses: format_courses(data.courses),
      registration_date: DateTime.utc_now() |> DateTime.truncate(:second),
      wizard_step: wizard_step && to_string(wizard_step)
    }
  end

  defp normalize_wizard_data(data) when is_map(data) do
    get = fn key -> Map.get(data, key) || Map.get(data, to_string(key)) end

    contact =
      case get.(:student_contact) do
        contact when is_binary(contact) ->
          contact
          |> String.replace(~r/[^\d]/, "")
          |> case do
            "" -> nil
            digits -> String.to_integer(digits)
          end

        contact when is_integer(contact) ->
          contact

        _ ->
          nil
      end

    %{
      student_id: get.(:student_id),
      student_names: get.(:student_names),
      student_email: get.(:student_email),
      student_contact: contact,
      program_id: get.(:program_id),
      program_name: get.(:program_name),
      academic_year: get.(:academic_year),
      semester: get.(:semester),
      intake: get.(:intake),
      courses: get.(:courses) || []
    }
  end

  def list_by_academics_status(status) do
    Repo.all(from r in Registration, where: r.accademics_status == ^status)
  end

  def list_by_payment_status(status) do
    Repo.all(from r in Registration, where: r.payment_status == ^status)
  end

  def list_by_hod_status(status) do
    Repo.all(
      from r in Registration,
        where: r.hod_status == ^status and is_nil(r.deleted_at),
        order_by: [desc: r.updated_at]
    )
  end

  def list_by_retention_status(status) do
    Repo.all(
      from r in Registration,
        where: r.retention_status == ^status and is_nil(r.deleted_at),
        order_by: [desc: r.updated_at]
    )
  end

  def count_by_academics_status(status) do
    Repo.aggregate(from(r in Registration, where: r.accademics_status == ^status), :count)
  end

  def count_by_payment_status(status) do
    Repo.aggregate(from(r in Registration, where: r.payment_status == ^status), :count)
  end

  def count_by_hod_status(status) do
    Repo.aggregate(from(r in Registration, where: r.hod_status == ^status), :count)
  end

  def count_by_retention_status(status) do
    Repo.aggregate(from(r in Registration, where: r.retention_status == ^status), :count)
  end

  def count_approved_today_by(field) do
    today = Date.utc_today()

    Repo.aggregate(
      from(r in Registration,
        where:
          fragment("DATE(?)", r.inserted_at) == ^today and
            field(r, ^field) == "APPROVED"
      ),
      :count
    )
  end

  def migrate_pending_registrations_workflow(old_id, new_id) do
    Repo.update_all(
      from(r in Registration,
        where: r.workflow_id == ^old_id and r.registration_status == "PENDING"
      ),
      set: [workflow_id: new_id]
    )
  end

  def changeset(registration, attrs) do
    Registration.changeset(registration, attrs)
  end

  def list_registrations do
    Repo.all(Registration)
  end

  def get_registration!(id), do: Repo.get!(Registration, id)

  @doc "Loads a registration with payment receipts for detail views."
  def get_registration_with_details!(id) do
    Registration
    |> Repo.get!(id)
    |> Repo.preload(:payment_receipts)
  end

  def get_registration(id), do: Repo.get(Registration, id)

  def get_registration_by_tracking_number(tracking_number) do
    Registration
    |> where([r], r.tracking_number == ^tracking_number)
    |> preload([:workflow, :payment_receipts])
    |> Repo.one()
  end

  def get_registration_by_student_id(student_id) do
    Repo.get_by(Registration, student_id: student_id)
  end

  def create_registration(attrs \\ %{}) do
    %Registration{}
    |> Registration.changeset(attrs)
    |> Repo.insert()
  end

  def update_registration(%Registration{} = registration, attrs) do
    registration
    |> Registration.changeset(attrs)
    |> Repo.update()
  end

  def delete_registration(%Registration{} = registration) do
    Repo.delete(registration)
  end

  @doc """
  Approves multiple registrations at a given stage in one action.
  Each registration still produces its own individual audit trail row.
  Returns `{ok_count, errors}` where `errors` is a list of `{id, reason}`.
  """
  def bulk_approve(registrations, actor, stage)
      when is_list(registrations) and stage in ~w(payment academics hod retention) do
    Enum.reduce(registrations, {0, []}, fn registration, {ok_count, errors} ->
      result =
        case stage do
          "payment" -> approve_payment(registration, actor)
          "academics" -> approve_academics(registration, actor)
          "hod" -> approve_hod(registration, actor)
          "retention" -> approve_retention(registration, actor)
        end

      case result do
        {:ok, _} -> {ok_count + 1, errors}
        {:error, reason} -> {ok_count, [{registration.id, reason} | errors]}
      end
    end)
  end

  # ── Real-time updates (FR5) ─────────────────────────────────────────────
  # Dashboards subscribe to this topic and refresh their assigns via
  # `handle_info/2` whenever any registration changes, so approver queues
  # and a student's own dashboard update live across sessions without a
  # manual page reload.

  @topic "registrations"

  def subscribe do
    Phoenix.PubSub.subscribe(CuzCoreConnect.PubSub, @topic)
  end

  defp broadcast(registration) do
    Phoenix.PubSub.broadcast(CuzCoreConnect.PubSub, @topic, {:registration_updated, registration})
    registration
  end

  # ── Audit log (FR7) ─────────────────────────────────────────────────────
  # Every transition below writes an insert-only row to
  # `tbl_registration_approvals` (via `CuzCoreConnect.Approvals.MemoApproval`)
  # capturing actor, action, resulting status, and reason.

  @doc """
  Records an immutable audit trail entry for a registration state transition.
  """
  def record_registration_action(registration, actor, action_type, status, comment \\ nil) do
    %MemoApproval{}
    |> MemoApproval.changeset(%{
      registration_id: registration.id,
      actionar_id: actor && Map.get(actor, :id),
      action_type: action_type,
      status: status,
      comment: comment,
      actioned_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()
  end

  @doc "Full, ordered audit trail for a single registration."
  def list_registration_actions(registration_id) do
    MemoApproval
    |> where([a], a.registration_id == ^registration_id)
    |> order_by([a], asc: a.inserted_at)
    |> Repo.all()
  end

  # ── Stage-guarded approve/reject (FR2, FR9, FR10) ───────────────────────
  #
  # Stage order is currently the fixed sequence baked into these functions
  # (Payment + Academics -> HOD -> Retention) rather than being read at
  # runtime from `tbl_registration_workflows.flow`. The admin "Registration
  # Work Flows" screen lets an admin author/activate a named flow and links
  # new registrations to it via `workflow_id`, but nothing in this module (or
  # anywhere else in the app) consults `flow` steps to decide the next
  # actionable stage - so it is NOT truly dynamic yet. Each function below
  # re-checks the required prior stage(s) before allowing an approval, so a
  # stage genuinely cannot be skipped even if a reviewer directly triggers the
  # LiveView event out of turn.

  def approve_payment(registration, actor) do
    transition(
      registration,
      actor,
      %{payment_status: "APPROVED", financial_status: "APPROVED"},
      "payment_approval",
      "approved"
    )
  end

  def reject_payment(registration, actor, reason) do
    reject(
      registration,
      actor,
      "payment",
      %{payment_status: "REJECTED", financial_status: "REJECTED"},
      "payment_approval",
      reason
    )
  end

  def approve_academics(registration, actor) do
    transition(
      registration,
      actor,
      %{accademics_status: "APPROVED"},
      "academics_approval",
      "approved"
    )
  end

  def reject_academics(registration, actor, reason) do
    reject(
      registration,
      actor,
      "academics",
      %{accademics_status: "REJECTED"},
      "academics_approval",
      reason
    )
  end

  def approve_hod(registration, actor) do
    if registration.accademics_status == "APPROVED" and registration.payment_status == "APPROVED" do
      transition(registration, actor, %{hod_status: "APPROVED"}, "hod_approval", "approved")
    else
      {:error, :stage_not_ready}
    end
  end

  def reject_hod(registration, actor, reason) do
    reject(registration, actor, "hod", %{hod_status: "REJECTED"}, "hod_approval", reason)
  end

  def approve_retention(registration, actor) do
    if registration.hod_status == "APPROVED" do
      transition(
        registration,
        actor,
        %{
          retention_status: "APPROVED",
          registration_status: "APPROVED",
          approval_level: "approved"
        },
        "retention_approval",
        "approved"
      )
      |> case do
        {:ok, updated} ->
          CuzCoreConnect.Registrations.RegistrationNotifier.deliver_completion_email(updated)
          {:ok, updated}

        error ->
          error
      end
    else
      {:error, :stage_not_ready}
    end
  end

  def reject_retention(registration, actor, reason) do
    reject(
      registration,
      actor,
      "retention",
      %{retention_status: "REJECTED"},
      "retention_approval",
      reason
    )
  end

  @doc """
  Lets a student revise and resubmit a registration that was rejected at some
  stage: resets that stage (and the overall status) back to PENDING so it
  re-enters the approval queue, rather than dead-ending at "rejected".
  """
  def resubmit_registration(%Registration{registration_status: "REJECTED"} = registration, actor) do
    stage_reset =
      case registration.rejected_stage do
        "payment" -> %{payment_status: "PENDING", financial_status: "PENDING"}
        "academics" -> %{accademics_status: "PENDING"}
        "hod" -> %{hod_status: "PENDING"}
        "retention" -> %{retention_status: "PENDING"}
        _ -> %{}
      end

    attrs =
      Map.merge(stage_reset, %{
        registration_status: "PENDING",
        approval_level: "pending",
        rejection_reason: nil,
        rejected_stage: nil
      })

    transition(registration, actor, attrs, "resubmission", "pending")
  end

  def resubmit_registration(%Registration{}, _actor), do: {:error, :not_rejected}

  defp reject(registration, actor, stage, status_attrs, action_type, reason) do
    attrs =
      Map.merge(status_attrs, %{
        registration_status: "REJECTED",
        approval_level: "rejected",
        rejection_reason: reason,
        rejected_stage: stage
      })

    case transition(registration, actor, attrs, action_type, "rejected", reason) do
      {:ok, updated} ->
        CuzCoreConnect.Registrations.RegistrationNotifier.deliver_stage_rejected_email(
          updated,
          stage,
          reason
        )

        {:ok, updated}

      error ->
        error
    end
  end

  defp transition(registration, actor, attrs, action_type, status, comment \\ nil) do
    result =
      Repo.transaction(fn ->
        with {:ok, updated} <- update_registration(registration, attrs),
             {:ok, _log} <-
               record_registration_action(updated, actor, action_type, status, comment) do
          updated
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

    case result do
      {:ok, updated} ->
        broadcast(updated)
        maybe_notify_approval(updated, action_type, status)
        maybe_notify_in_app(updated, action_type, status, actor, comment)
        {:ok, updated}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @stage_by_action %{
    "payment_approval" => "payment",
    "academics_approval" => "academics",
    "hod_approval" => "hod",
    "retention_approval" => "retention"
  }

  defp maybe_notify_approval(registration, action_type, "approved") do
    case Map.fetch(@stage_by_action, action_type) do
      {:ok, stage} ->
        CuzCoreConnect.Registrations.RegistrationNotifier.deliver_stage_approved_email(
          registration,
          stage
        )

      :error ->
        :ok
    end
  end

  defp maybe_notify_approval(_registration, _action_type, _status), do: :ok

  defp maybe_notify_in_app(registration, action_type, status, actor, reason)
       when status in ["approved", "rejected"] do
    case Map.fetch(@stage_by_action, action_type) do
      {:ok, stage} ->
        CuzCoreConnect.Notifications.notify_registration_stage(
          registration,
          stage,
          status,
          actor,
          reason
        )

      :error ->
        :ok
    end
  end

  defp maybe_notify_in_app(_registration, _action_type, _status, _actor, _reason), do: :ok

  def change_registration(%Registration{} = registration, attrs \\ %{}) do
    Registration.changeset(registration, attrs)
  end

  @doc """
  Returns list of pending registrations with pagination support.
  """
  def list_pending_registrations(search_params) do
    Registration
    |> handle_registration_filter(search_params)
    |> order_by(desc: :registration_date)
    |> Scrivener.paginate(Scrivener.Config.new(Repo, @pagination, search_params))
  end

  @doc """
  Returns pending registrations for export (no pagination).
  """
  def pending_registrations_export(search_params) do
    Registration
    |> handle_registration_filter(search_params)
    |> order_by(desc: :registration_date)
    |> Repo.all()
  end

  def list_approved_registrations do
    Repo.all(
      from r in Registration,
        where: r.registration_status == "APPROVED" or r.approval_level == "approved"
    )
  end

  def update_approval_level(registration, level, approved_by \\ %{}) do
    registration
    |> Registration.changeset(%{
      approval_level: level,
      approved_by: approved_by
    })
    |> Repo.update()
  end

  def create_registration(user, registration_data, opts \\ []) do
    draft = Keyword.get(opts, :draft)
    tracking_number = generate_tracking_number()
    data = normalize_wizard_data(registration_data)

    student_id =
      data.student_id ||
        (user && extract_student_id(user && (Map.get(user, :user) || user)))

    student_names =
      data.student_names || (user && extract_student_name(user && (Map.get(user, :user) || user)))

    student_email =
      data.student_email ||
        (user && extract_student_email(user && (Map.get(user, :user) || user)))

    student_contact =
      data.student_contact ||
        (user && extract_student_contact(user && (Map.get(user, :user) || user)))

    attrs = %{
      student_id: student_id,
      student_names: student_names,
      student_email: student_email,
      student_contact: student_contact,
      student_program_details: %{
        "program_id" => data.program_id,
        "program_name" => data.program_name,
        "academic_year" => data.academic_year,
        "semester" => data.semester,
        "intake" => data.intake
      },
      student_courses: format_courses(data.courses),
      registration_date: DateTime.utc_now() |> DateTime.truncate(:second),
      tracking_number: tracking_number,
      approval_level: "pending",
      approved_by: %{},
      payment_status: "PENDING",
      retention_status: "PENDING",
      accademics_status: "PENDING",
      hod_status: "PENDING",
      financial_status: "PENDING",
      registration_status: "PENDING",
      wizard_step: nil
    }

    result =
      case draft do
        %Registration{registration_status: "DRAFT"} = existing ->
          existing
          |> Registration.submit_changeset(attrs)
          |> Repo.update()

        _ ->
          %Registration{}
          |> Registration.submit_changeset(attrs)
          |> Repo.insert()
      end

    case result do
      {:ok, registration} ->
        actor = user && Map.get(user, :user)
        record_registration_action(registration, actor, "submission", "pending")
        broadcast(registration)
        CuzCoreConnect.Registrations.RegistrationNotifier.deliver_submission_email(registration)
        _ = CuzCoreConnect.Communications.create_registration_message(registration)
        _ = CuzCoreConnect.Notifications.notify_registration_submitted(registration, actor)
        {:ok, registration}

      error ->
        error
    end
  end

  def create_payment_receipt(receipt_attrs) do
    %PaymentReceipt{}
    |> PaymentReceipt.changeset(receipt_attrs)
    |> Repo.insert()
  end

  @doc """
  Copies an uploaded LiveView temp file into `priv/static/uploads/receipts/`
  and inserts a `PaymentReceipt` row. Returns `{:ok, receipt}` or `{:error, reason}`.
  """
  def persist_payment_receipt(registration, tmp_path, entry_meta)
      when is_binary(tmp_path) and is_map(entry_meta) do
    original_filename =
      entry_meta[:client_name] || entry_meta["client_name"] || "receipt"

    content_type =
      entry_meta[:client_type] || entry_meta["client_type"]

    file_size =
      entry_meta[:client_size] || entry_meta["client_size"] ||
        case File.stat(tmp_path) do
          {:ok, %{size: size}} -> size
          _ -> nil
        end

    uploaded_by =
      entry_meta[:uploaded_by_student_id] ||
        entry_meta["uploaded_by_student_id"] ||
        registration.student_id

    ext =
      original_filename
      |> Path.extname()
      |> String.downcase()
      |> case do
        "" -> extension_for_mime(PaymentReceipt.normalize_mime(content_type))
        other -> other
      end

    storage_key = "receipts/#{registration.id}-#{Ecto.UUID.generate()}#{ext}"
    dest = upload_path(storage_key)

    with :ok <- File.mkdir_p(Path.dirname(dest)),
         :ok <- copy_upload!(tmp_path, dest),
         true <- File.exists?(dest),
         {:ok, receipt} <-
           create_payment_receipt(%{
             original_filename: original_filename,
             storage_key: storage_key,
             content_type: content_type,
             file_size: file_size,
             uploaded_by_student_id: to_string(uploaded_by),
             student_registration_id: registration.id
           }) do
      {:ok, receipt}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        _ = File.rm(dest)
        {:error, changeset}

      false ->
        _ = File.rm(dest)
        {:error, :file_missing_after_copy}

      {:error, reason} ->
        _ = File.rm(dest)
        {:error, reason}
    end
  end

  @doc "Absolute filesystem path for a storage_key under priv/static/uploads."
  def upload_path(storage_key) when is_binary(storage_key) do
    Path.join([uploads_root(), storage_key])
  end

  def uploads_root do
    Path.join([
      :code.priv_dir(:cuz_core_connect) |> to_string(),
      "static",
      "uploads"
    ])
  end

  @doc """
  Resolves candidate filesystem paths for a receipt so both relative
  storage keys and legacy absolute/temp paths can be found when possible.
  """
  def receipt_file_paths(%PaymentReceipt{} = receipt) do
    key = receipt.storage_key || ""

    [
      key,
      upload_path(key),
      Path.join([uploads_root(), Path.basename(key)]),
      Path.join([uploads_root(), "receipts", Path.basename(key)])
    ]
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.uniq()
  end

  def read_receipt_file(%PaymentReceipt{} = receipt) do
    receipt
    |> receipt_file_paths()
    |> Enum.find_value(fn path ->
      case File.read(path) do
        {:ok, data} -> {:ok, data, path}
        _ -> nil
      end
    end)
    |> case do
      {:ok, data, path} -> {:ok, data, path}
      nil -> {:error, :not_found}
    end
  end

  defp copy_upload!(source, dest) do
    case File.cp(source, dest) do
      :ok ->
        :ok

      {:error, _reason} ->
        # Fallback for cross-device temp dirs where rename/cp can fail oddly.
        case File.read(source) do
          {:ok, data} -> File.write(dest, data)
          error -> error
        end
    end
  end

  defp extension_for_mime("image/jpeg"), do: ".jpg"
  defp extension_for_mime("image/png"), do: ".png"
  defp extension_for_mime("image/webp"), do: ".webp"
  defp extension_for_mime("application/pdf"), do: ".pdf"
  defp extension_for_mime(_), do: ""

  @doc """
  Get a payment receipt by id.
  Returns the `%PaymentReceipt{}` or `nil` if not found.
  """
  def get_payment_receipt(id) do
    Repo.get(CuzCoreConnect.Students.PaymentReceipt, id)
  end

  # Private helper functions
  defp generate_tracking_number do
    # Generate a unique tracking number with timestamp and random component
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(3) |> Base.encode16(case: :lower)
    "REG-#{timestamp}-#{random}"
  end

  defp extract_student_id(user) do
    Map.get(user, :student_number) || Map.get(user, :student_id) || to_string(user.id)
  end

  defp extract_student_email(user) do
    # Extract student email from user - adjust based on your user schema
    user && Map.get(user, :email)
  end

  defp extract_student_name(user) do
    # Extract student name from user - adjust based on your user schema
    user &&
      (Map.get(user, :full_name) || Map.get(user, :name) || "#{user.first_name} #{user.last_name}" ||
         "Unknown")
  end

  defp extract_student_contact(user) do
    # Extract student contact from user - adjust based on your user schema
    user && (Map.get(user, :phone) || Map.get(user, :contact) || 0)
  end

  # ── File Retrieval ────────────────────────────────────────────────────────────

  def get_payment_receipt_url(registration_id, receipt_id) do
    with {:ok, receipt} <- get_payment_receipt(registration_id, receipt_id) do
      {:ok, "/uploads/#{receipt.storage_key}"}
    else
      error -> error
    end
  end

  def get_payment_receipt(registration_id, receipt_id) do
    case Repo.get_by(PaymentReceipt,
           id: receipt_id,
           student_registration_id: registration_id
         ) do
      nil -> {:error, :not_found}
      receipt -> {:ok, receipt}
    end
  end

  def list_payment_receipts(registration_id) do
    PaymentReceipt
    |> where([pr], pr.student_registration_id == ^registration_id)
    |> Repo.all()
  end

  defp format_courses(courses) when is_list(courses) do
    selected =
      Enum.map(courses, fn course ->
        %{
          id: Map.get(course, :id) || Map.get(course, "id"),
          code: Map.get(course, :code) || Map.get(course, "code"),
          name:
            Map.get(course, :title) || Map.get(course, :name) || Map.get(course, "title") ||
              Map.get(course, "name"),
          credits: Map.get(course, :credits) || Map.get(course, "credits") || 0
        }
      end)

    %{
      selected_courses: selected,
      total_credit_hours: Enum.sum(Enum.map(selected, & &1.credits)),
      course_count: length(selected)
    }
  end

  defp format_courses(_), do: %{}

  # ==================== REGISTRATION FILTER HELPERS ====================

  defp handle_registration_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        registration_isearch_filter(query, sanitize_term(value))

      {"student_names", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("lower(?) LIKE lower(?)", r.student_names, ^"%#{sanitize_term(value)}%")
        )

      {"tracking_number", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("lower(?) LIKE lower(?)", r.tracking_number, ^"%#{sanitize_term(value)}%")
        )

      {"approval_level", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("lower(?) LIKE lower(?)", r.approval_level, ^"%#{sanitize_term(value)}%")
        )

      {"payment_status", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("lower(?) LIKE lower(?)", r.payment_status, ^"%#{sanitize_term(value)}%")
        )

      {"from", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("CAST(? AS DATE) >= ?", r.registration_date, ^to_db_date(value))
        )

      {"to", value}, query when byte_size(value) > 0 ->
        where(
          query,
          [r],
          fragment("CAST(? AS DATE) <= ?", r.registration_date, ^to_db_date(value))
        )

      {_, _}, query ->
        query
    end)
  end

  defp registration_isearch_filter(query, search_term) do
    where(
      query,
      [r],
      fragment("lower(?) LIKE lower(?)", r.student_names, ^"%#{search_term}%") or
        fragment("lower(?) LIKE lower(?)", r.tracking_number, ^"%#{search_term}%") or
        fragment("lower(?) LIKE lower(?)", r.approval_level, ^"%#{search_term}%") or
        fragment("lower(?) LIKE lower(?)", r.payment_status, ^"%#{search_term}%")
    )
  end

  defp sanitize_term(term), do: String.trim(term)
  defp to_db_date(date), do: Date.from_iso8601!(date)
end
