defmodule CuzCoreConnectWeb.LandingLiveTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "GET /Student/registration renders the LiveView and responds to events", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/Student/registration")

    assert html =~ "Live View Demo"
    assert render_click(view, :increment) =~ "1"
  end
end
