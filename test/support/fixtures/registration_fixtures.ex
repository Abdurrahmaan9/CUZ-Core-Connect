defmodule CuzCoreConnect.RegistrationFixtures do
  @moduledoc """
  Test helpers for creating registrations via the
  `CuzCoreConnect.Registrations` context.
  """

  alias CuzCoreConnect.Registrations
  alias CuzCoreConnect.Workflows

  @doc """
  Ensures there is an active registration workflow (required by
  `Registration.changeset/2`) and returns it.
  """
  def active_workflow_fixture do
    case Workflows.get_active_registration_flow() do
      nil ->
        {:ok, workflow} =
          Workflows.create_registration_flow(%{
            name: "Standard Flow #{System.unique_integer([:positive])}",
            is_active: true,
            flow: [
              %{
                step_no: 1,
                description: "Payment",
                actionar_type: "specific_department",
                role_key: "finance"
              },
              %{
                step_no: 2,
                description: "Academics",
                actionar_type: "specific_department",
                role_key: "academics"
              },
              %{
                step_no: 3,
                description: "HOD",
                actionar_type: "specific_department",
                role_key: "hod"
              },
              %{
                step_no: 4,
                description: "Retention",
                actionar_type: "specific_department",
                role_key: "retention"
              }
            ]
          })

        workflow

      workflow ->
        workflow
    end
  end

  def registration_fixture(attrs \\ %{}) do
    active_workflow_fixture()

    default_attrs = %{
      student_id: "STU#{System.unique_integer([:positive])}",
      student_names: "Test Student",
      student_email: "student#{System.unique_integer([:positive])}@example.com",
      student_contact: "0971234567",
      student_program_details: %{},
      student_courses: %{},
      registration_date: DateTime.utc_now() |> DateTime.truncate(:second),
      tracking_number: "REG-#{System.unique_integer([:positive])}",
      approval_level: "pending",
      payment_status: "PENDING",
      retention_status: "PENDING",
      accademics_status: "PENDING",
      hod_status: "PENDING",
      financial_status: "PENDING",
      registration_status: "PENDING"
    }

    {:ok, registration} =
      default_attrs
      |> Map.merge(Map.new(attrs))
      |> Registrations.create_registration()

    registration
  end
end
