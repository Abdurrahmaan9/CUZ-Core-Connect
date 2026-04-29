defmodule CuzCoreConnect.Repo.Migrations.CreateTblPaymentReceipt do
  use Ecto.Migration

  def change do
    create table(:tbl_payment_receipts) do
      add :original_filename, :string, null: false
      add :storage_key, :string, null: false
      add :content_type, :string, null: false
      add :file_size, :integer
      add :uploaded_by_student_id, :string

      add :student_registration_id,
          references(:tbl_registration, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tbl_payment_receipts, [:student_registration_id])
  end
end
