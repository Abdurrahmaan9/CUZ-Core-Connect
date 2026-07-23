defmodule CuzCoreConnect.CommunicationsTest do
  use CuzCoreConnect.DataCase, async: true

  alias CuzCoreConnect.Communications
  import CuzCoreConnect.RegistrationFixtures

  test "published announcements are listed for the landing marquee" do
    {:ok, published} =
      Communications.create_announcement(%{
        title: "Open registration",
        body: "Registration is open",
        status: "published"
      })

    {:ok, _draft} =
      Communications.create_announcement(%{
        title: "Draft only",
        body: "Hidden",
        status: "draft"
      })

    titles = Communications.list_published_announcements() |> Enum.map(& &1.title)
    assert published.title in titles
    refute "Draft only" in titles
  end

  test "registration creates a landing message" do
    registration = registration_fixture()

    assert {:ok, message} = Communications.create_registration_message(registration)
    assert message.source == "registration"
    assert message.show_on_landing
    assert message.registration_id == registration.id

    landing = Communications.list_landing_messages()
    assert Enum.any?(landing, &(&1.id == message.id))
  end

  test "contact form message is created unread and hidden from landing" do
    assert {:ok, message} =
             Communications.create_contact_message(%{
               name: "Visitor",
               email: "visitor@example.com",
               subject: "Help",
               body: "I need assistance"
             })

    assert message.status == "unread"
    refute message.show_on_landing
  end
end
