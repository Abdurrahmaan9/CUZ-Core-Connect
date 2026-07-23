defmodule CuzCoreConnect.Communications.EmailLog do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(sent failed)

  schema "tbl_email_logs" do
    field :to_address, :string
    field :from_address, :string
    field :subject, :string
    field :body, :string
    field :status, :string, default: "sent"
    field :api_client_enabled, :boolean, default: false
    field :error_message, :string
    field :notif_type, :string
    field :adapter, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [
      :to_address,
      :from_address,
      :subject,
      :body,
      :status,
      :api_client_enabled,
      :error_message,
      :notif_type,
      :adapter
    ])
    |> validate_required([:to_address, :subject, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
