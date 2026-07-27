defmodule CuzCoreConnect.Registrations.Registration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_registration" do
    field :student_id, :string
    field :student_names, :string
    field :student_email, :string, redact: true
    field :student_contact, :string
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
    field :rejection_reason, :string
    field :rejected_stage, :string
    field :wizard_step, :string
    field :deleted_at, :naive_datetime
    field :under_scholarship, :boolean, default: false

    has_many :payment_receipts, CuzCoreConnect.Students.PaymentReceipt,
      foreign_key: :student_registration_id

    belongs_to :workflow, CuzCoreConnect.Workflows.RegistrationWorkflow
    belongs_to :scholarship, CuzCoreConnect.Scholarships.Scholarship

    timestamps(type: :utc_datetime)
  end

  @draft_cast [
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
    :registration_status,
    :wizard_step,
    :deleted_at,
    :under_scholarship,
    :scholarship_id
  ]

  def changeset(registration, attrs) do
    registration
    |> cast(attrs, @draft_cast ++ [:rejection_reason, :rejected_stage])
    |> put_active_workflow()
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
    |> validate_student_contact()
  end

  @doc """
  Relaxed changeset for in-progress wizard saves. Does not attach a workflow
  or require a tracking number — those happen on final submit.
  """
  def draft_changeset(registration, attrs) do
    registration
    |> cast(attrs, @draft_cast)
    |> put_change(:registration_status, "DRAFT")
    |> put_change(:approval_level, "draft")
    |> put_change(:payment_status, "DRAFT")
    |> put_change(:retention_status, "DRAFT")
    |> put_change(:accademics_status, "DRAFT")
    |> put_change(:hod_status, "DRAFT")
    |> put_change(:financial_status, "DRAFT")
    |> validate_required([:student_id, :student_names, :student_email, :student_contact])
    |> validate_email()
    |> validate_student_contact()
  end

  @doc """
  Promotes a draft (or creates a new row) into the approval workflow.
  """
  def submit_changeset(registration, attrs) do
    registration
    |> cast(attrs, @draft_cast ++ [:rejection_reason, :rejected_stage])
    |> put_change(:registration_status, "PENDING")
    |> put_change(:approval_level, "pending")
    |> put_change(:payment_status, "PENDING")
    |> put_change(:retention_status, "PENDING")
    |> put_change(:accademics_status, "PENDING")
    |> put_change(:hod_status, "PENDING")
    |> put_change(:financial_status, "PENDING")
    |> put_change(:wizard_step, nil)
    |> put_active_workflow()
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
      :registration_status
    ])
    |> validate_email()
    |> validate_student_contact()
  end

  defp put_active_workflow(changeset) do
    case get_field(changeset, :workflow_id) do
      nil ->
        case CuzCoreConnect.Workflows.get_active_registration_flow() do
          nil -> add_error(changeset, :workflow_id, "No active registration workflow found")
          workflow -> put_change(changeset, :workflow_id, workflow.id)
        end

      _ ->
        changeset
    end
  end

  def validate_email(changeset) do
    validate_change(changeset, :student_email, fn :student_email, email ->
      if is_binary(email) and String.contains?(email, "@") do
        []
      else
        [student_email: "Email must contain @"]
      end
    end)
  end

  def validate_student_contact(changeset) do
    validate_change(changeset, :student_contact, fn :student_contact, contact ->
      if valid_contact?(contact) do
        []
      else
        [
          student_contact:
            "Use 7–15 digits, or + and 8–15 digits (E.164), e.g. 0978957640 or +260978957640"
        ]
      end
    end)
  end

  @doc """
  Normalizes a contact number for storage: optional leading `+`, digits only.
  """
  def normalize_contact(nil), do: nil

  def normalize_contact(contact) when is_integer(contact),
    do: normalize_contact(Integer.to_string(contact))

  def normalize_contact(contact) when is_binary(contact) do
    trimmed = String.trim(contact)
    has_plus? = String.starts_with?(trimmed, "+")
    digits = String.replace(trimmed, ~r/[^\d]/, "")

    cond do
      digits == "" -> nil
      has_plus? -> "+" <> digits
      true -> digits
    end
  end

  def normalize_contact(_), do: nil

  @doc """
  Industry-standard phone check (E.164-friendly):
  - without `+`: 7–15 digits
  - with `+`: `+` followed by 8–15 digits (country code + national number)
  """
  def valid_contact?(nil), do: false

  def valid_contact?(contact) when is_integer(contact),
    do: valid_contact?(Integer.to_string(contact))

  def valid_contact?(contact) when is_binary(contact) do
    case normalize_contact(contact) do
      "+" <> digits -> Regex.match?(~r/^[1-9]\d{7,14}$/, digits)
      digits when is_binary(digits) -> Regex.match?(~r/^\d{7,15}$/, digits)
      _ -> false
    end
  end

  def valid_contact?(_), do: false

  def draft?(%__MODULE__{registration_status: "DRAFT"}), do: true
  def draft?(_), do: false
end
