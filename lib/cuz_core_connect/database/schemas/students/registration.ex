defmodule CuzCoreConnect.Students.Registration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_registration" do
    field :student_id, :string
    field :student_names, :string
    field :student_email, :string, redact: true
    field :student_contact, :integer
    field :student_program_details, :map, default: %{}
    field :student_courses, :map, default: %{}
    field :registration_date, :utc_datetime
    field :tracking_number, :string
    field :approval_level, :string
    field :approved_by, :map, default: %{}
    field :payment_status, :string, default: "PENDING"
    field :retention_status, :string, default: "PENDING"
    field :accademics_status, :string, default: "PENDING"
    field :hod_status, :string, default: "PENDING"
    field :financial_status, :string, default: "PENDING"
    field :registration_status, :string, default: "PENDING"
    has_many :payment_receipts, CuzCoreConnect.Students.PaymentReceipt, foreign_key: :student_registration_id

    timestamps(type: :utc_datetime)
  end

  def changeset(registration, attrs) do
    registration
    |> cast(attrs,
    [
    :student_id,
    :student_names,
    :student_email,
    :student_contact,
    :student_program_details,
    :student_courses,
    :registration_date,
    :tracking_number,
    :approval_level,
    :payment_status,
    :retention_status,
    :accademics_status,
    :hod_status,
    :financial_status,
    :registration_status
    ])

    |> validate_required([
      :student_id,
      :student_names,
      :student_email,
      :student_contact,
      :student_program_details,
      :student_courses,
      :registration_date,
      :tracking_number,
      :approval_level,
      :payment_status,
      :retention_status,
      :accademics_status,
      :hod_status,
      :financial_status,
      :registration_status
      ])
      
    |> validate_email()
  end

  def validate_email(changeset) do
    validate_change(changeset, :student_email, fn :student_email, email ->
      if String.contains?(email, "@") do
        []
      else
        [student_email: "Email must contain @"]
      end
    end)
  end

end
