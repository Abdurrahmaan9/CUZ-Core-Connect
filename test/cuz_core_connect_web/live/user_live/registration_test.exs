defmodule CuzCoreConnectWeb.UserLive.RegistrationTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CuzCoreConnect.AccountFixtures
  import Swoosh.TestAssertions

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.StudentEmail

  describe "Registration page" do
    test "renders student registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Student portal sign up"
      assert html =~ "Student number"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/student/dashboard")

      assert {:ok, _conn} = result
    end

    test "suggests institutional email while typing names", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      html =
        lv
        |> element("#registration_form")
        |> render_change(%{
          student: %{
            "student_number" => "202512345",
            "first_name" => "Jane",
            "last_name" => "Doe",
            "middle_name" => "",
            "use_suggested_email" => "true",
            "email" => ""
          }
        })

      suggested = StudentEmail.suggest("Jane", "Doe", "202512345")
      assert suggested == "jd202512345@#{StudentEmail.domain()}"
      assert html =~ suggested
    end

    test "renders errors for invalid student number", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(student: %{"student_number" => "123"})

      assert result =~ "must be at least 6 digits"
    end
  end

  describe "register student" do
    test "creates student account and emails credentials", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      student_number = "20#{System.unique_integer([:positive])}" |> String.slice(0, 9)
      # ensure at least 6 digits
      student_number = String.pad_trailing(student_number, 6, "0")
      email = StudentEmail.suggest("Ada", "Lovelace", student_number)

      {:ok, _lv, html} =
        lv
        |> form("#registration_form",
          student: %{
            "student_number" => student_number,
            "first_name" => "Ada",
            "last_name" => "Lovelace",
            "middle_name" => "",
            "use_suggested_email" => "true",
            "email" => email
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Login credentials were sent"

      user = Accounts.get_user_by_email(email)
      assert user.user_role == "student"
      assert user.student_number == student_number
      assert user.first_name == "Ada"
      assert user.last_name == "Lovelace"
      refute is_nil(user.confirmed_at)

      assert_email_sent(to: email, subject: "Your CUZ Core Connect account")
    end

    test "allows a custom email when suggested email is unchecked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      student_number = "30#{System.unique_integer([:positive])}" |> String.slice(0, 9)
      student_number = String.pad_trailing(student_number, 6, "0")
      custom_email = "custom#{System.unique_integer([:positive])}@example.com"

      {:ok, _lv, _html} =
        lv
        |> form("#registration_form",
          student: %{
            "student_number" => student_number,
            "first_name" => "Alan",
            "last_name" => "Turing",
            "middle_name" => "Math",
            "use_suggested_email" => "false",
            "email" => custom_email
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      user = Accounts.get_user_by_email(custom_email)
      assert user.middle_name == "Math"
      assert user.student_number == student_number
    end

    test "renders errors for duplicated email", %{conn: conn} do
      email = "taken#{System.unique_integer([:positive])}@students.cavendish.co.zm"
      _user = user_fixture(%{email: email})

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      student_number = "40#{System.unique_integer([:positive])}" |> String.slice(0, 9)
      student_number = String.pad_trailing(student_number, 6, "0")

      result =
        lv
        |> form("#registration_form",
          student: %{
            "student_number" => student_number,
            "first_name" => "Dup",
            "last_name" => "Email",
            "use_suggested_email" => "false",
            "email" => email
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Log in"
    end
  end
end
