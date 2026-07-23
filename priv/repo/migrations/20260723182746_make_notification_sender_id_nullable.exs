defmodule CuzCoreConnect.Repo.Migrations.MakeNotificationSenderIdNullable do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE tbl_notifications DROP CONSTRAINT IF EXISTS tbl_notifications_sender_id_fkey"

    execute "ALTER TABLE tbl_notifications ALTER COLUMN sender_id DROP NOT NULL"

    execute """
    ALTER TABLE tbl_notifications
      ADD CONSTRAINT tbl_notifications_sender_id_fkey
      FOREIGN KEY (sender_id) REFERENCES tbl_users(id)
      ON DELETE SET NULL
    """
  end

  def down do
    execute "ALTER TABLE tbl_notifications DROP CONSTRAINT IF EXISTS tbl_notifications_sender_id_fkey"

    execute "ALTER TABLE tbl_notifications ALTER COLUMN sender_id SET NOT NULL"

    execute """
    ALTER TABLE tbl_notifications
      ADD CONSTRAINT tbl_notifications_sender_id_fkey
      FOREIGN KEY (sender_id) REFERENCES tbl_users(id)
      ON DELETE CASCADE
    """
  end
end
