defmodule CuzCoreConnect.Registration do
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Registrations.Registration
  import Ecto.Query

  @pagination [page_size: 10]

  def changeset(registration, attrs) do
    Registration.changeset(registration, attrs)
  end

  def list_registrations do
    Repo.all(Registration)
  end

  def get_registration!(id), do: Repo.get!(Registration, id)

  def get_registration_by_tracking_number(tracking_number) do
    Repo.get_by(Registration, tracking_number: tracking_number)
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
    Repo.all(from r in Registration, where: r.approval_level == "approved")
  end

  def update_approval_level(registration, level, approved_by \\ %{}) do
    registration
    |> Registration.changeset(%{
      approval_level: level,
      approved_by: approved_by
    })
    |> Repo.update()
  end

  def create_registration(user, registration_data) do
    # Generate tracking number
    tracking_number = generate_tracking_number()

    # Use personal info from wizard data (handle anonymous registration)
    student_id = registration_data.student_id || registration_data.student_number || (user && extract_student_id(user))
    student_names = registration_data.student_names || (user && extract_student_name(user))
    student_email = registration_data.student_email || (user && extract_student_email(user))
    student_contact = registration_data.student_contact || (user && extract_student_contact(user))

    # Prepare registration attributes
    attrs = %{
      student_id: student_id,
      student_names: student_names,
      student_email: student_email,
      student_contact: student_contact,
      student_program_details: %{
        program_id: registration_data.program_id,
        program_name: registration_data.program_name,
        academic_year: registration_data.academic_year,
        semester: registration_data.semester,
        intake: registration_data.intake
      },
      student_courses: format_courses(registration_data.courses),
      registration_date: DateTime.utc_now(),
      tracking_number: tracking_number,
      approval_level: "pending",
      approved_by: %{},
      payment_status: "pending"
    }

    %Registration{}
    |> Registration.changeset(attrs)
    |> Repo.insert()
  end

  def create_payment_receipt(receipt_attrs) do
    alias CuzCoreConnect.Students.PaymentReceipt

    %PaymentReceipt{}
    |> PaymentReceipt.changeset(receipt_attrs)
    |> Repo.insert()
  end

  # Private helper functions
  defp generate_tracking_number do
    # Generate a unique tracking number with timestamp and random component
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(3) |> Base.encode16(case: :lower)
    "REG-#{timestamp}-#{random}"
  end

  defp extract_student_id(user) do
    # Extract student ID from user - adjust based on your user schema
    Map.get(user, :student_id) || to_string(user.id)
  end

  defp extract_student_email(user) do
    # Extract student email from user - adjust based on your user schema
    user && Map.get(user, :email)
  end

  defp extract_student_name(user) do
    # Extract student name from user - adjust based on your user schema
    user && (Map.get(user, :full_name) || Map.get(user, :name) || "#{user.first_name} #{user.last_name}" || "Unknown")
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
    %{
      selected_courses: Enum.map(courses, fn course ->
        %{
          id: course.id,
          code: course.code,
          name: course.name,
          credit_hours: course.credit_hours
        }
      end),
      total_credit_hours: Enum.sum(Enum.map(courses, & &1.credit_hours)),
      course_count: length(courses)
    }
  end

  defp format_courses(_), do: %{}

  # ==================== REGISTRATION FILTER HELPERS ====================

  defp handle_registration_filter(query, params) do
    Enum.reduce(params, query, fn
      {"isearch", value}, query when byte_size(value) > 0 ->
        registration_isearch_filter(query, sanitize_term(value))

      {"student_names", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("lower(?) LIKE lower(?)", r.student_names, ^"%#{sanitize_term(value)}%"))

      {"tracking_number", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("lower(?) LIKE lower(?)", r.tracking_number, ^"%#{sanitize_term(value)}%"))

      {"approval_level", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("lower(?) LIKE lower(?)", r.approval_level, ^"%#{sanitize_term(value)}%"))

      {"payment_status", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("lower(?) LIKE lower(?)", r.payment_status, ^"%#{sanitize_term(value)}%"))

      {"from", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("CAST(? AS DATE) >= ?", r.registration_date, ^to_db_date(value)))

      {"to", value}, query when byte_size(value) > 0 ->
        where(query, [r], fragment("CAST(? AS DATE) <= ?", r.registration_date, ^to_db_date(value)))

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
