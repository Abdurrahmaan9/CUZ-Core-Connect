defmodule CuzCoreConnectWeb.PageController do
  use CuzCoreConnectWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
