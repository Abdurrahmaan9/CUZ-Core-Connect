defmodule CuzCoreConnect.Mailer do
  @moduledoc """
  Application mailer. Every `deliver/2` call is recorded in `tbl_email_logs`.

  When `:swoosh, :api_client` is `false` (Local / Test), deliveries are always
  logged as `sent`. When an API client is configured, the log status mirrors
  the real adapter result (`sent` or `failed`).
  """
  use Swoosh.Mailer, otp_app: :cuz_core_connect

  alias CuzCoreConnect.Communications

  def deliver(email, config \\ [])

  def deliver(email, config) do
    result = super(email, config)
    _ = log_delivery(email, result)
    result
  end

  @doc """
  Returns whether Swoosh is configured with a real HTTP API client.
  """
  def api_client_enabled? do
    case Application.get_env(:swoosh, :api_client) do
      false -> false
      nil -> false
      _module -> true
    end
  end

  @doc """
  Maps a deliver result to a log status.

  Offline / local mode (`api_client` false) always yields `"sent"`.
  """
  def status_for_result(result) do
    if api_client_enabled?() do
      case result do
        {:ok, _} -> "sent"
        {:error, _} -> "failed"
        _ -> "failed"
      end
    else
      "sent"
    end
  end

  defp log_delivery(email, result) do
    api? = api_client_enabled?()
    status = status_for_result(result)

    attrs = %{
      to_address: format_recipients(email.to),
      from_address: format_mailbox(email.from),
      subject: email.subject || "(no subject)",
      body: email.text_body || email.html_body,
      status: status,
      api_client_enabled: api?,
      error_message: error_message(result, api?),
      notif_type: Map.get(email.private || %{}, :notif_type),
      adapter: adapter_name()
    }

    case Communications.create_email_log(attrs) do
      {:ok, log} ->
        {:ok, log}

      {:error, changeset} ->
        require Logger
        Logger.warning("Failed to persist email log: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  rescue
    exception ->
      require Logger
      Logger.warning("Failed to persist email log: #{Exception.message(exception)}")
      {:error, exception}
  end

  defp error_message({:error, reason}, true), do: inspect(reason)
  defp error_message(_, _), do: nil

  defp adapter_name do
    conf = Application.get_env(:cuz_core_connect, __MODULE__, [])
    conf[:adapter] |> to_string()
  end

  defp format_recipients(nil), do: ""

  defp format_recipients(list) when is_list(list) do
    list
    |> Enum.map(&format_mailbox/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end

  defp format_recipients(other), do: format_mailbox(other)

  defp format_mailbox(nil), do: ""
  defp format_mailbox({name, address}) when is_binary(address) and name in [nil, ""], do: address
  defp format_mailbox({name, address}) when is_binary(address), do: "#{name} <#{address}>"
  defp format_mailbox(address) when is_binary(address), do: address
  defp format_mailbox(other), do: inspect(other)
end
