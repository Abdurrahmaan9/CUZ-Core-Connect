defmodule CuzCoreConnectWeb.RbacTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CuzCoreConnect.AccountFixtures

  @roles ~w(admin academics finance hod retention student)

  @protected_routes [
    {"/admin/dashboard", "admin"},
    {"/admin/programmes", "admin"},
    {"/admin/courses", "admin"},
    {"/admin/user-accounts/internal", "admin"},
    {"/admin/workflows/registration", "admin"},
    {"/academics/dashboard", "academics"},
    {"/finance/dashboard", "finance"},
    {"/hod/dashboard", "hod"},
    {"/retention/dashboard", "retention"},
    {"/student/dashboard", "student"}
  ]

  defp role_user(role) do
    user_fixture(%{user_role: role, is_active: true, status: "ACTIVE"})
  end

  for {path, allowed_role} <- @protected_routes do
    test "role #{allowed_role} can load #{path}" do
      path = unquote(path)
      allowed_role = unquote(allowed_role)
      user = role_user(allowed_role)
      {:ok, _view, html} = live(log_in_user(build_conn(), user), path)
      assert html =~ "<"
    end

    for other_role <- @roles -- [allowed_role] do
      test "role #{other_role} is redirected away from #{path}" do
        path = unquote(path)
        other_role = unquote(other_role)
        user = role_user(other_role)

        assert {:error, {:redirect, %{to: redirect_to, flash: flash}}} =
                 live(log_in_user(build_conn(), user), path)

        assert flash["error"] == "Access denied."
        refute redirect_to == path
      end
    end
  end

  test "unauthenticated visitor is redirected to login from a protected dashboard" do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} =
             live(build_conn(), "/student/dashboard")
  end
end
