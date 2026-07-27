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
      add :description, :text
      add :paths, {:array, :string}, default: []
      add :actions, {:array, :string}, default: []
      add :role, :string, null: false, default: "admin"
      add :deleted_at, :naive_datetime

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
      add :deleted_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_user_page_access) do
      add :user_id, references(:tbl_users, on_delete: :delete_all), null: false
      add :page_id, references(:tbl_pages, on_delete: :delete_all), null: false
      add :actions, {:array, :string}, default: []
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

    create_if_not_exists table(:tbl_registration_workflows) do
      add :name, :string
      add :status, :string
      add :flow, {:array, :map}
      add :description, :string
      add :is_active, :boolean, default: false
      add :deleted_at, :naive_datetime

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

      add :retention_status, :string, null: false
      add :accademics_status, :string, null: false
      add :hod_status, :string, null: false
      add :financial_status, :string, null: false
      add :registration_status, :string, null: false
      add :deleted_at, :naive_datetime
      add :workflow_id, references(:tbl_registration_workflows, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_registration_approvals) do
      add :status, :string
      add :can_reject, :boolean, default: false
      add :comment, :string
      add :actioned_at, :utc_datetime
      add :action_type, :string
      add :registration_id, references(:tbl_registration, on_delete: :delete_all), null: false
      add :actionar_id, references(:tbl_users, on_delete: :nilify_all)
      add :is_reassigned, :boolean, default: false

      timestamps()
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

    create_if_not_exists table(:tbl_programmes) do
      add :name, :string, null: false
      add :code, :string, null: false
      add :description, :string
      add :duration_years, :integer, default: 4
      add :is_active, :boolean, default: true

      timestamps()
    end

    create_if_not_exists table(:tbl_courses) do
      add :title, :string, null: false
      add :description, :string
      add :code, :string, null: false
      add :credits, :integer, default: 3
      add :is_active, :boolean, default: true

      timestamps()
    end

    create_if_not_exists table(:tbl_program_courses) do
      add :program_id, references(:tbl_programmes, on_delete: :delete_all), null: false
      add :course_id, references(:tbl_courses, on_delete: :delete_all), null: false
      add :year, :integer, null: false
      add :semester, :integer, null: false
      add :is_core, :boolean, default: false
      add :is_active, :boolean, default: true

      timestamps()
    end

    create_if_not_exists table(:tbl_scholarships) do
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :sponsor, :string
      add :coverage, :string, default: "full"
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_email_logs) do
      add :to_address, :string, null: false
      add :from_address, :string
      add :subject, :string, null: false
      add :body, :text
      add :status, :string, null: false, default: "sent"
      add :api_client_enabled, :boolean, null: false, default: false
      add :error_message, :text
      add :notif_type, :string
      add :adapter, :string

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_announcements) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :audience, :string, default: "All Users"
      add :author, :string, default: "Admin"
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime
      add :views, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists table(:tbl_site_messages) do
      add :name, :string, null: false
      add :email, :string
      add :subject, :string, null: false
      add :body, :text, null: false
      add :source, :string, null: false, default: "contact"
      add :status, :string, null: false, default: "unread"
      add :priority, :string, default: "normal"
      add :show_on_landing, :boolean, default: false, null: false
      add :registration_id, references(:tbl_registration, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end
  end

  def alter_tables() do
    alter table(:tbl_registration) do
      add_if_not_exists :under_scholarship, :boolean, default: false, null: false
      add_if_not_exists :scholarship_id, :id

      modify :tracking_number, :string, null: true, from: {:string, null: false}
      add_if_not_exists :wizard_step, :string
      add_if_not_exists :rejection_reason, :string
      add_if_not_exists :rejected_stage, :string
    end

    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'tbl_registration_scholarship_id_fkey'
      ) THEN
        ALTER TABLE tbl_registration
          ADD CONSTRAINT tbl_registration_scholarship_id_fkey
          FOREIGN KEY (scholarship_id) REFERENCES tbl_scholarships(id)
          ON DELETE SET NULL;
      END IF;
    END $$;
    """

    alter table(:tbl_users) do
      add_if_not_exists :student_number, :string
      add_if_not_exists :first_name, :string
      add_if_not_exists :last_name, :string
      add_if_not_exists :middle_name, :string
    end

    execute """
    ALTER TABLE tbl_registration
      ALTER COLUMN student_contact TYPE varchar(32)
      USING student_contact::varchar
    """
    execute "ALTER TABLE tbl_notifications DROP CONSTRAINT IF EXISTS tbl_notifications_sender_id_fkey"

    execute "ALTER TABLE tbl_notifications ALTER COLUMN sender_id DROP NOT NULL"

    execute """
    ALTER TABLE tbl_notifications
      ADD CONSTRAINT tbl_notifications_sender_id_fkey
      FOREIGN KEY (sender_id) REFERENCES tbl_users(id)
      ON DELETE SET NULL
    """

    execute "REVOKE UPDATE, DELETE ON tbl_registration_approvals FROM PUBLIC",
            "GRANT UPDATE, DELETE ON tbl_registration_approvals TO PUBLIC"
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
    create_if_not_exists unique_index(:tbl_registration_workflows, [:is_active],
                           where: "is_active = true",
                           name: :one_active_registration_workflow
                         )
    create_if_not_exists index(:tbl_registration, [:scholarship_id])

    create_if_not_exists index(:tbl_pages, [:deleted_at])
    create_if_not_exists index(:tbl_pages, [:role])
    create_if_not_exists index(:tbl_pages, [:deleted_at, :role])

    create_if_not_exists unique_index(:tbl_programmes, [:code])
    create_if_not_exists index(:tbl_programmes, [:is_active])

    create_if_not_exists unique_index(:tbl_courses, [:code])
    create_if_not_exists index(:tbl_courses, [:is_active])

    create_if_not_exists unique_index(:tbl_program_courses, [
                           :program_id,
                           :course_id,
                           :year,
                           :semester
                         ])

    create_if_not_exists index(:tbl_program_courses, [:program_id])
    create_if_not_exists index(:tbl_program_courses, [:course_id])
    create_if_not_exists index(:tbl_program_courses, [:is_active])

    create_if_not_exists unique_index(:tbl_user_page_access, [:user_id, :page_id])
    create_if_not_exists index(:tbl_user_page_access, [:user_id])

    create_if_not_exists unique_index(:tbl_scholarships, [:code])
    create_if_not_exists index(:tbl_scholarships, [:status])

    create_if_not_exists index(:tbl_email_logs, [:status])
    create_if_not_exists index(:tbl_email_logs, [:inserted_at])
    create_if_not_exists index(:tbl_email_logs, [:to_address])

    create_if_not_exists unique_index(:tbl_users, [:student_number],
                           where: "student_number IS NOT NULL",
                           name: :tbl_users_student_number_index
                         )

    create_if_not_exists index(:tbl_announcements, [:status])
    create_if_not_exists index(:tbl_announcements, [:published_at])

    create_if_not_exists index(:tbl_site_messages, [:status])
    create_if_not_exists index(:tbl_site_messages, [:source])
    create_if_not_exists index(:tbl_site_messages, [:show_on_landing])
  end

  def drop_tables() do
    # Drop values that cannot fit in a 32-bit integer before reverting.
    execute """
    UPDATE tbl_registration
    SET student_contact = NULL
    WHERE student_contact ~ '[^0-9]'
       OR length(regexp_replace(student_contact, '[^0-9]', '', 'g')) > 9
       OR CAST(regexp_replace(student_contact, '[^0-9]', '', 'g') AS bigint) > 2147483647
    """

    execute """
    ALTER TABLE tbl_registration
      ALTER COLUMN student_contact TYPE integer
      USING NULLIF(regexp_replace(student_contact, '[^0-9]', '', 'g'), '')::integer
    """

    execute "ALTER TABLE tbl_notifications DROP CONSTRAINT IF EXISTS tbl_notifications_sender_id_fkey"

    # System / sender-less notifications cannot satisfy NOT NULL on rollback.
    execute "DELETE FROM tbl_notifications WHERE sender_id IS NULL"

    execute "ALTER TABLE tbl_notifications ALTER COLUMN sender_id SET NOT NULL"

    execute """
    ALTER TABLE tbl_notifications
      ADD CONSTRAINT tbl_notifications_sender_id_fkey
      FOREIGN KEY (sender_id) REFERENCES tbl_users(id)
      ON DELETE CASCADE
    """

    # Drafts are allowed to have a null tracking_number; remove them before
    # restoring the NOT NULL constraint on rollback.
    execute """
    DELETE FROM tbl_registration
    WHERE tracking_number IS NULL
    """

    alter table(:tbl_registration) do
      modify :tracking_number, :string, null: false, from: {:string, null: true}
      remove_if_exists :wizard_step, :string
    end
  end
end
