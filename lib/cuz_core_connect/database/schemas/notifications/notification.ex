defmodule CuzCoreConnect.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending_review approved rejected comment system alert warning
               info error success)
  @types ~w(document application system_message)

  schema "tbl_notifications" do
    field :status, :string, default: "pending_review"
    field :type, :string, default: "document"
    field :message, :string
    field :read, :boolean, default: false
    field :action_url, :string
    field :sender_name, :string
    field :document_name, :string
    field :comments, :string
    field :document_id, :string

    belongs_to :user, CuzCoreConnect.Accounts.User
    belongs_to :sender, CuzCoreConnect.Accounts.User

    timestamps(
      type: :naive_datetime,
      autogenerate: {CuzCoreConnect.LocalTimestamp, :autogenerate, []}
    )
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :status,
      :type,
      :message,
      :read,
      :action_url,
      :sender_name,
      :document_name,
      :document_id,
      :comments,
      :user_id,
      :sender_id
    ])
    |> validate_required([:message, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
  end
end
