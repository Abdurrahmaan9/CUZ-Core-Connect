defmodule CuzCoreConnectWeb.Admin.EmailLogsTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CuzCoreConnect.AccountFixtures

  alias CuzCoreConnect.Communications
  alias CuzCoreConnect.Mailer

  setup %{conn: conn} do
    admin =
      user_fixture(%{
        email: "admin-email-logs-#{System.unique_integer()}@example.com",
        username: "admin_logs_#{System.unique_integer()}",
        user_role: "admin"
      })

    %{conn: log_in_user(conn, admin), admin: admin}
  end

  test "lists outbound email logs", %{conn: conn} do
    {:ok, _} =
      Mailer.deliver(
        Swoosh.Email.new()
        |> Swoosh.Email.to("logged@example.com")
        |> Swoosh.Email.from("noreply@example.com")
        |> Swoosh.Email.subject("Portal credentials")
        |> Swoosh.Email.text_body("password here")
        |> Swoosh.Email.put_private(:notif_type, "account_credentials")
      )

    {:ok, view, html} = live(conn, ~p"/admin/email-logs")

    assert html =~ "Email Logs"
    assert html =~ "Portal credentials"
    assert html =~ "logged@example.com"
    assert has_element?(view, "#email-log-#{List.first(Communications.list_email_logs()).id}")
  end

  test "filters failed logs", %{conn: conn} do
    {:ok, _} =
      Communications.create_email_log(%{
        to_address: "fail@example.com",
        subject: "Failed send",
        status: "failed",
        api_client_enabled: true,
        error_message: ":timeout"
      })

    {:ok, view, _html} = live(conn, ~p"/admin/email-logs")

    view |> element("button", "Failed") |> render_click()
    assert has_element?(view, "td", "Failed send")
  end
end
