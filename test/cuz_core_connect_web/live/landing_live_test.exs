defmodule CuzCoreConnectWeb.LandingLiveTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "GET /student/registration renders the registration wizard LiveView", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/student/registration")

    assert html =~ "Course Registration"
    assert html =~ "Personal Info"
  end
end
