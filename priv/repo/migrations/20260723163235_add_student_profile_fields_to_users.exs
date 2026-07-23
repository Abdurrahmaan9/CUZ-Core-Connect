defmodule CuzCoreConnect.Repo.Migrations.AddStudentProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:tbl_users) do
      add :student_number, :string
      add :first_name, :string
      add :last_name, :string
      add :middle_name, :string
    end

    create_if_not_exists unique_index(:tbl_users, [:student_number],
                           where: "student_number IS NOT NULL",
                           name: :tbl_users_student_number_index
                         )
  end
end
