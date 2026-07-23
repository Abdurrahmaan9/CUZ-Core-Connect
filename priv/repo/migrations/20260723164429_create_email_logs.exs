defmodule CuzCoreConnect.Repo.Migrations.CreateEmailLogs do
  use Ecto.Migration

  def change do
    create table(:tbl_email_logs) do
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

    create index(:tbl_email_logs, [:status])
    create index(:tbl_email_logs, [:inserted_at])
    create index(:tbl_email_logs, [:to_address])
  end
end
