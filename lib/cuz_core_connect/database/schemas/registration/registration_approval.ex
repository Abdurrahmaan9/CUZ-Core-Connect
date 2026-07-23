defmodule CuzCoreConnect.Approvals.MemoApproval do
  @moduledoc """
  Immutable audit trail entry for a registration state transition (submit,
  approve, reject, admin override, resubmission).

  This schema is intentionally INSERT-only: it exposes no update/delete
  changeset. Every state transition on a `Registration` should write one of
  these rows so the full approval history is reconstructable per-registration
  (actor, role, from/to status, reason, and timestamp).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_registration_approvals" do
    field :status, :string, default: "pending"
    field :comment, :string
    field :action_type, :string
    field :actioned_at, :utc_datetime
    field :is_reassigned, :boolean, default: false
    field :can_reject, :boolean, default: false

    belongs_to :registration, CuzCoreConnect.Registrations.Registration
    belongs_to :actionar, CuzCoreConnect.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for inserting a new audit trail row. There is
  deliberately no changeset variant intended for updates.
  """
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
    |> validate_required([:status, :action_type, :registration_id])
    |> validate_inclusion(:status, ~w(approved rejected pending reviewed re-assigned))
  end
end
