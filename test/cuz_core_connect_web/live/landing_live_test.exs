defmodule CuzCoreConnectWeb.LandingLiveTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "GET /live renders the LiveView and responds to events", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/live")

    assert html =~ "Live View Demo"
    assert render_click(view, :increment) =~ "1"
  end
end
