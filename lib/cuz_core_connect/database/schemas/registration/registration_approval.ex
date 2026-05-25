defmodule CuzCoreConnect.Approvals.MemoApproval do
  use Ecto.Schema
  import Ecto.Changeset

  schema "memo_approvals" do
    field :status, :string, default: "pending"
    field :comment, :string
    field :action_type, :string
    field :actioned_at, :utc_datetime
    field :is_reassigned, :boolean, default: false

    belongs_to :registration, CuzCoreConnect.Registrations.Registration
    belongs_to :actionar, CuzCoreConnect.Accounts.User

    timestamps(type: :utc_datetime)
    # timestamps(
    #   type: :naive_datetime,
    #   autogenerate: {CuzCoreConnect.LocalTimestamp, :autogenerate, []}
    # )
  end

  def changeset(memo_approval, attrs) do
    memo_approval
    |> cast(attrs, [
      :status,
      :comment,
      :action_type,
      :registration_id,
      :is_reassigned,
      :actionar_id,
      :actioned_at,
      :can_reject
    ])
    |> validate_required([:status, :action_type, :registration_id, :actionar_id])
    |> validate_inclusion(:status, ~w(approved rejected pending reviewed re-assigned))
  end
end
