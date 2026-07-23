defmodule CuzCoreConnectWeb.CertificateControllerTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import CuzCoreConnect.AccountFixtures
  import CuzCoreConnect.RegistrationFixtures

  test "owner can view proof of registration for an APPROVED registration", %{conn: conn} do
    student = user_fixture(%{user_role: "student"})

    registration =
      registration_fixture(%{
        student_id: to_string(student.id),
        registration_status: "APPROVED"
      })

    conn = conn |> log_in_user(student) |> get(~p"/registrations/#{registration.id}/certificate")
    assert html_response(conn, 200) =~ "Proof of Registration"
    assert html_response(conn, 200) =~ registration.tracking_number
  end

  test "approved registration is available by tracking number without login", %{conn: conn} do
    registration =
      registration_fixture(%{
        registration_status: "APPROVED",
        tracking_number: "REG-proof-public-test"
      })

    conn = get(conn, ~p"/registration/tracking/#{registration.tracking_number}/proof")
    assert html_response(conn, 200) =~ "Proof of Registration"
    assert html_response(conn, 200) =~ registration.tracking_number
  end

  test "proof of registration is unavailable for non-approved registrations", %{conn: conn} do
    student = user_fixture(%{user_role: "student"})

    registration =
      registration_fixture(%{
        student_id: to_string(student.id),
        registration_status: "PENDING"
      })

    conn = conn |> log_in_user(student) |> get(~p"/registrations/#{registration.id}/certificate")
    assert redirected_to(conn) == "/"
  end

  test "pending registration cannot be opened by tracking proof route", %{conn: conn} do
    registration =
      registration_fixture(%{
        registration_status: "PENDING",
        tracking_number: "REG-proof-pending-test"
      })

    conn = get(conn, ~p"/registration/tracking/#{registration.tracking_number}/proof")
    assert redirected_to(conn) == "/"
  end
end
