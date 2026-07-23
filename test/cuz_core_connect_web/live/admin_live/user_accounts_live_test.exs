defmodule CuzCoreConnectWeb.Admin.UserAccountsLiveTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CuzCoreConnect.AccountFixtures

  setup do
    admin = user_fixture(%{user_role: "admin", is_active: true, status: "ACTIVE"})
    %{conn: log_in_user(build_conn(), admin), admin: admin}
  end

  test "internal users page creates a staff user and emails credentials", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/user-accounts/internal")

    view |> element("button", "New user") |> render_click()
    assert_patch(view, ~p"/admin/user-accounts/internal/new")
    assert has_element?(view, "#internal-user-form")

    email = "staff#{System.unique_integer()}@cuz.test"
    username = "staff#{System.unique_integer()}"

    view
    |> form("#internal-user-form",
      user: %{email: email, username: username, user_role: "finance", is_active: "true"}
    )
    |> render_submit()

    assert_patch(view, ~p"/admin/user-accounts/internal")
    html = render(view)
    assert html =~ email
    assert html =~ "finance"
    assert html =~ "Login credentials were emailed"
  end

  test "external users page creates a student user and emails credentials", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/user-accounts/external")

    view |> element("button", "New user") |> render_click()
    assert_patch(view, ~p"/admin/user-accounts/external/new")
    assert has_element?(view, "#external-user-form")

    email = "student#{System.unique_integer()}@cuz.test"
    username = "student#{System.unique_integer()}"

    view
    |> form("#external-user-form", user: %{email: email, username: username, is_active: "true"})
    |> render_submit()

    assert_patch(view, ~p"/admin/user-accounts/external")
    html = render(view)
    assert html =~ email
    assert html =~ "student"
    assert html =~ "Login credentials were emailed"
  end

  test "closing create modal does not crash", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/user-accounts/internal/new")
    assert has_element?(view, "#internal-user-form-modal")

    view |> element("button", "Cancel") |> render_click()
    assert_patch(view, ~p"/admin/user-accounts/internal")
    refute has_element?(view, "#internal-user-form-modal")
  end
end
