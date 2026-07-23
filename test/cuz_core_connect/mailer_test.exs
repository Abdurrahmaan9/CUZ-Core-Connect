defmodule CuzCoreConnect.MailerTest do
  use CuzCoreConnect.DataCase, async: false

  alias CuzCoreConnect.Communications
  alias CuzCoreConnect.Mailer

  describe "status_for_result/1" do
    test "always returns sent when api_client is false" do
      previous = Application.get_env(:swoosh, :api_client)
      Application.put_env(:swoosh, :api_client, false)

      try do
        assert Mailer.status_for_result({:ok, %{}}) == "sent"
        assert Mailer.status_for_result({:error, :timeout}) == "sent"
      after
        Application.put_env(:swoosh, :api_client, previous)
      end
    end

    test "mirrors deliver result when api_client is enabled" do
      previous = Application.get_env(:swoosh, :api_client)
      Application.put_env(:swoosh, :api_client, Swoosh.ApiClient.Req)

      try do
        assert Mailer.status_for_result({:ok, %{id: "1"}}) == "sent"
        assert Mailer.status_for_result({:error, :provider_down}) == "failed"
      after
        Application.put_env(:swoosh, :api_client, previous)
      end
    end
  end

  describe "deliver/1 logging" do
    test "persists a sent email log when api_client is false" do
      assert Mailer.api_client_enabled?() == false

      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to("student@example.com")
        |> Swoosh.Email.from({"CUZ - Core Connect", "contact@coreconnect.lobnode.com"})
        |> Swoosh.Email.subject("Test log email")
        |> Swoosh.Email.text_body("Hello from the mailer log test.")
        |> Swoosh.Email.put_private(:notif_type, "test")

      assert {:ok, _} = Mailer.deliver(email)

      [log | _] = Communications.list_email_logs()
      assert log.to_address == "student@example.com"
      assert log.subject == "Test log email"
      assert log.status == "sent"
      assert log.api_client_enabled == false
      assert log.notif_type == "test"
      assert is_nil(log.error_message)
    end
  end
end
