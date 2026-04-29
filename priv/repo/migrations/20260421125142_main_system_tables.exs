defmodule CuzCoreConnect.Repo.Migrations.MainSystemTables do
  use Ecto.Migration

  def up do
    create_tables()
    alter_tables()
    index_tables()
    # Oban.Migrations.up()
  end

  def down do
    drop_tables()
    # Oban.Migrations.down()
  end

  def create_tables do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create_if_not_exists table(:tbl_pages) do
      add :name, :string, null: false
      add :paths, {:array, :string}, default: []
      add :actions, {:array, :string}, default: ["view", "create", "edit", "export", "delete"]
      add :is_admin, :boolean
      add :description, :text
      add :is_deleted, :boolean

      timestamps()
    end

    create_if_not_exists table(:tbl_users) do
      add :email, :citext, null: false
      add :username, :string, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :user_role, :string, default: "student"
      add :status, :string
      add :is_active, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_users_tokens) do
      add :user_id, references(:tbl_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create_if_not_exists table(:tbl_notifications) do
      add :status, :string
      add :type, :string
      add :message, :string
      add :read, :boolean
      add :action_url, :string
      add :sender_name, :string
      add :document_name, :string
      add :document_id, :string
      add :comments, :string

      add :user_id, references(:tbl_users, on_delete: :delete_all), null: false
      add :sender_id, references(:tbl_users, on_delete: :delete_all), null: false
      timestamps()
    end

    create_if_not_exists table(:tbl_registration) do
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

    create_if_not_exists table(:tbl_payment_receipts) do
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
  end

  def index_tables() do
    create_if_not_exists unique_index(:tbl_users, [:email])
    create_if_not_exists unique_index(:tbl_users, [:username])
    create_if_not_exists index(:tbl_users_tokens, [:user_id])
    create_if_not_exists unique_index(:tbl_users_tokens, [:context, :token])
    create_if_not_exists index(:tbl_payment_receipts, [:student_registration_id])

    create_if_not_exists index(:tbl_registration, [:student_id])
    create_if_not_exists index(:tbl_registration, [:tracking_number])
    create_if_not_exists index(:tbl_registration, [:approval_level])
    create_if_not_exists index(:tbl_registration, [:payment_status])

    create_if_not_exists index(:tbl_pages, [:is_deleted])
    create_if_not_exists index(:tbl_pages, [:is_admin])
    create_if_not_exists index(:tbl_pages, [:is_deleted, :is_admin])
  end

  def alter_tables() do
  end

  def drop_tables() do
  end
end
