defmodule CuzCoreConnect.Registration do
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Students.Registration
  import Ecto.Query

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

  def list_pending_registrations do
    Repo.all(from r in Registration, where: r.approval_level == "pending")
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
end
