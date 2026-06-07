defmodule CuzCoreConnect.Accounts.UserRolePermissionSeeds do
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Accounts

  @default_password "OWKq3Xw1KiqF!"

  def plant_roles do
    clear_existing_data()

    create_super_admin!("System Admin", "admin@cuz.coreconnect.edu")
    create_student_user!("Honore Niyomukiza", "hn104734@students.cuz.coreconnect.edu")
    create_internal_user!("Academics User", "academics@cuz.coreconnect.edu", "academics")
    create_internal_user!("Finance User", "finance@cuz.coreconnect.edu", "finance")
    create_internal_user!("HOD User", "hod@cuz.coreconnect.edu", "hod")

    IO.puts("""
    ═══════════════════════════════════════════════
    ✅ Users / Roles & Permission Seed complete
    ═══════════════════════════════════════════════
    """)
  end

  defp clear_existing_data do
    # Repo.delete_all(Accounts.UserRolePermission)
    Repo.delete_all(Accounts.User)
    Repo.delete_all(Accounts.UserToken)
  end

  defp create_super_admin!(username, email, password \\ @default_password) do
    {:ok, user} =
      Accounts.register_user(
        %{
          "username" => username,
          "email" => email,
          "password" => password,
          "is_active" => true,
          "status" => "ACTIVE",
          "user_role" => "admin"
        }
      )

    {:ok, user} = Repo.update(Accounts.User.confirm_changeset(user))
    user
  end

  defp create_internal_user!(username, email, role, password \\ @default_password) do
    {:ok, user} =
      Accounts.register_user(
        %{
          "username" => username,
          "email" => email,
          "password" => password,
          "is_active" => true,
          "status" => "ACTIVE",
          "user_role" => role
        }
      )

    {:ok, user} = Repo.update(Accounts.User.confirm_changeset(user))
    user
  end

  defp create_student_user!(username, email, password \\ @default_password) do
    {:ok, user} =
      Accounts.register_user(
        %{
          "username" => username,
          "email" => email,
          "password" => password,
          "is_active" => true,
          "status" => "ACTIVE",
          "user_role" => "student"
        }
      )

    {:ok, user} = Repo.update(Accounts.User.confirm_changeset(user))
    user
  end
end
