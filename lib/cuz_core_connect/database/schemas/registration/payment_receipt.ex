defmodule CuzCoreConnect.Students.PaymentReceipt do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_content_types ~w(
    image/jpeg
    image/png
    image/webp
    application/pdf
  )

  schema "tbl_payment_receipts" do
    # "receipt_april.jpg" — what the user named it
    field :original_filename, :string
    # "receipts/uuid.jpg" — path relative to priv/static/uploads
    field :storage_key, :string
    # "image/jpeg", "application/pdf"
    field :content_type, :string
    # bytes
    field :file_size, :integer
    # for auditing
    field :uploaded_by_student_id, :string

    belongs_to :student_registration,
               CuzCoreConnect.Registrations.Registration

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
    |> normalize_content_type()
    |> validate_required([
      :original_filename,
      :storage_key,
      :content_type,
      :student_registration_id
    ])
    |> validate_inclusion(:content_type, @allowed_content_types)
    # 5MB cap
    |> validate_number(:file_size, less_than_or_equal_to: 5_000_000)
  end

  def normalize_mime(nil), do: nil
  def normalize_mime(""), do: nil

  def normalize_mime(type) when is_binary(type) do
    type
    |> String.trim()
    |> String.downcase()
    |> case do
      "image/jpg" -> "image/jpeg"
      "image/pjpeg" -> "image/jpeg"
      "image/x-png" -> "image/png"
      "application/x-pdf" -> "application/pdf"
      other -> other
    end
  end

  def mime_from_filename(filename) when is_binary(filename) do
    case filename |> Path.extname() |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".webp" -> "image/webp"
      ".pdf" -> "application/pdf"
      _ -> nil
    end
  end

  def mime_from_filename(_), do: nil

  defp normalize_content_type(changeset) do
    filename = get_field(changeset, :original_filename)
    raw = get_change(changeset, :content_type) || get_field(changeset, :content_type)

    normalized =
      normalize_mime(raw) ||
        mime_from_filename(filename)

    if normalized do
      put_change(changeset, :content_type, normalized)
    else
      changeset
    end
  end
end
