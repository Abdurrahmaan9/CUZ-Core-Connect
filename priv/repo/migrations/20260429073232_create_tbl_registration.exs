defmodule CuzCoreConnect.Repo.Migrations.CreateTblRegistration do
  use Ecto.Migration

  def change do
    create table(:tbl_registration) do
      add :student_id, :string, null: false
      add :student_names, :string, null: false
      add :student_email, :string, null: false
      add :student_contact, :integer, null: false
      add :student_program_details, :map, default: %{}
      add :student_courses, :map, default: %{}
      add :registration_date, :utc_datetime, null: false
      add :tracking_number, :string, null: false
      add :approval_level, :string, null: false
      add :approved_by, :map, default: %{}
      add :payment_status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tbl_registration, [:student_id])
    create index(:tbl_registration, [:tracking_number])
    create index(:tbl_registration, [:approval_level])
    create index(:tbl_registration, [:payment_status])
  end
end
