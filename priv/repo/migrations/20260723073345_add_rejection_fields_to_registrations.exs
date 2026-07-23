defmodule CuzCoreConnect.Repo.Migrations.AddRejectionFieldsToRegistrations do
  use Ecto.Migration

  def change do
    alter table(:tbl_registration) do
      # Captures why a registration was rejected at whatever stage rejected it,
      # and which stage rejected it, so the student can be told what to fix and
      # a resubmission can re-enter the pipeline at the right point.
      add :rejection_reason, :string
      add :rejected_stage, :string
    end

    # Best-effort, defense-in-depth guard against accidental UPDATE/DELETE of
    # the approval/audit trail from any role connecting as PUBLIC (i.e. any
    # role without an explicit grant). Note: this does NOT stop the table
    # owner (typically the same role the app itself connects as in this
    # project's current single-role setup) because Postgres table owners
    # always retain implicit privileges regardless of REVOKE. True DB-level
    # immutability against the app's own role would require running the app
    # under a separate, non-owner, INSERT-only role - a deployment/infra
    # decision left for discussion rather than silently changed here.
    execute "REVOKE UPDATE, DELETE ON tbl_registration_approvals FROM PUBLIC",
            "GRANT UPDATE, DELETE ON tbl_registration_approvals TO PUBLIC"
  end
end
