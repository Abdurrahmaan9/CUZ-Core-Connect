defmodule CuzCoreConnect.Accounts.UserRolePermissionSeeds do
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Accounts

  @default_password "OWKq3Xw1KiqF!"

  def plant_roles do
    clear_existing_data()

    create_super_admin!("System Admin", "admin@cuz.coreconnect.edu")

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

  # defp create_user_roles(roles) do
  #   Enum.each(roles, fn role_permissions_attrs ->
  #     Repo.insert!(
  #       Accounts.UserRolePermission.changeset(
  #         %Accounts.UserRolePermission{},
  #         role_permissions_attrs
  #       )
  #     )
  #   end)
  # end

  # defp create_user!(username, email) do
  #   {:ok, user} =
  #     Accounts.register_user(
  #       %{
  #         "username" => username,
  #         "email" => email,
  #         "password" => "TestPassword123!@#"
  #       },
  #       true
  #     )

  #   {:ok, user} = Repo.update(Accounts.User.confirm_changeset(user))
  #   user
  # end

  # defp create_admin_user!(username, email, role) do
  #   {:ok, user} =
  #     Accounts.register_user(%{
  #       "username" => username,
  #       "email" => email,
  #       "password" => @default_password,
  #       "is_admin" => true
  #     })

  #   {:ok, user} = Repo.update(Accounts.User.confirm_changeset(user))
  #   # Merchants.add_admin_user_to_profile(user, role.id)
  #   user
  # end

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
end
