defmodule CuzCoreConnect.Repo.Migrations.CreateAnnouncementsAndSiteMessages do
  use Ecto.Migration

  def change do
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

    create_if_not_exists index(:tbl_announcements, [:status])
    create_if_not_exists index(:tbl_announcements, [:published_at])

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

    create_if_not_exists index(:tbl_site_messages, [:status])
    create_if_not_exists index(:tbl_site_messages, [:source])
    create_if_not_exists index(:tbl_site_messages, [:show_on_landing])
  end
end
