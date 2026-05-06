defmodule CuzCoreConnect.Students.PaymentReceipt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_payment_receipts" do
    field :original_filename, :string      # "receipt_april.jpg" — what the user named it
    field :storage_key, :string            # "receipts/2026/04/uuid.jpg" — path in storage
    field :content_type, :string           # "image/jpeg", "application/pdf"
    field :file_size, :integer             # bytes
    field :uploaded_by_student_id, :string # for auditing

    belongs_to :student_registration,
      CuzCoreConnect.Students.Registration

    timestamps(type: :utc_datetime)
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [
      :original_filename,
      :storage_key,
      :content_type,
      :file_size,
      :uploaded_by_student_id,
      :student_registration_id
    ])
    |> validate_required([:original_filename, :storage_key, :content_type, :student_registration_id])
    |> validate_inclusion(:content_type, [
      "image/jpeg",
      "image/png",
      "image/webp",
      "application/pdf"
    ])
    |> validate_number(:file_size, less_than_or_equal_to: 5_000_000) # 5MB cap
  end
end
