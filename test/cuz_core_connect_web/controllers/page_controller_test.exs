defmodule CuzCoreConnectWeb.PageControllerTest do
  use CuzCoreConnectWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Transform University Registration"
  end
end
