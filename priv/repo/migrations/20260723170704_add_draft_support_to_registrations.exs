defmodule CuzCoreConnect.Repo.Migrations.AddDraftSupportToRegistrations do
  use Ecto.Migration

  def change do
    alter table(:tbl_registration) do
      modify :tracking_number, :string, null: true, from: {:string, null: false}
      add :wizard_step, :string
    end
  end
end
