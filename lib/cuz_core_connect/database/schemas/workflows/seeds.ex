defmodule CuzCoreConnect.Workflows.Seeds do
  @moduledoc false

  alias CuzCoreConnect.Workflows

  @doc """
  Ensures there is an active default registration workflow so newly
  submitted registrations can be linked via `workflow_id`.
  """
  def plant do
    case Workflows.get_active_registration_flow() do
      nil ->
        {:ok, workflow} =
          Workflows.create_registration_flow(%{
            name: "Standard Registration Flow",
            description: "Default multi-stage approval path",
            is_active: true,
            flow: [
              %{
                step_no: 1,
                description: "Payment verification",
                actionar_type: "specific_department",
                role_key: "finance"
              },
              %{
                step_no: 2,
                description: "Academic review",
                actionar_type: "specific_department",
                role_key: "academics"
              },
              %{
                step_no: 3,
                description: "HOD review",
                actionar_type: "specific_department",
                role_key: "hod"
              },
              %{
                step_no: 4,
                description: "Retention final approval",
                actionar_type: "specific_department",
                role_key: "retention"
              }
            ]
          })

        IO.puts("✅ Seeded active registration workflow ##{workflow.id}")

      workflow ->
        IO.puts("ℹ️  Active registration workflow already present (##{workflow.id})")
    end
  end
end
