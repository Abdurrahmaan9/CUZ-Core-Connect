defmodule CuzCoreConnectWeb.Student.TrackingTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CuzCoreConnect.RegistrationFixtures

  alias CuzCoreConnect.Registrations
  import CuzCoreConnect.AccountFixtures

  test "shows approved status after final retention approval", %{conn: conn} do
    registration = registration_fixture()

    {:ok, registration} =
      Registrations.approve_academics(
        registration,
        unconfirmed_user_fixture(%{user_role: "academics"})
      )

    {:ok, registration} =
      Registrations.approve_payment(
        registration,
        unconfirmed_user_fixture(%{user_role: "finance"})
      )

    {:ok, registration} =
      Registrations.approve_hod(registration, unconfirmed_user_fixture(%{user_role: "hod"}))

    {:ok, registration} =
      Registrations.approve_retention(
        registration,
        unconfirmed_user_fixture(%{user_role: "retention"})
      )

    {:ok, view, _html} =
      live(conn, ~p"/registration/tracking/#{registration.tracking_number}")

    assert has_element?(view, "#stage-retention")
    assert render(view) =~ "Approved"
    assert render(view) =~ "View Proof"
    assert render(view) =~ "Download / Print"

    assert has_element?(
             view,
             "a[href='/registration/tracking/#{registration.tracking_number}/proof']"
           )
  end

  test "search finds registration and shows pending pipeline", %{conn: conn} do
    registration = registration_fixture()

    {:ok, view, _html} = live(conn, ~p"/registration/tracking")

    view
    |> form("#tracking-search-form", %{tracking_number: registration.tracking_number})
    |> render_submit()

    assert_patch(view, ~p"/registration/tracking/#{registration.tracking_number}")
    assert has_element?(view, "#stage-finance")
    assert has_element?(view, "#stage-academics")
    assert render(view) =~ "Pending"
  end
end
