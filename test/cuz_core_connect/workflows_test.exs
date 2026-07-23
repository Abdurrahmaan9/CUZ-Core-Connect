defmodule CuzCoreConnect.WorkflowsTest do
  use CuzCoreConnect.DataCase, async: true

  alias CuzCoreConnect.Workflows
  import CuzCoreConnect.RegistrationFixtures

  defp flow_attrs(name, active?) do
    %{
      name: name,
      description: "Test flow",
      is_active: active?,
      flow: [
        %{
          step_no: 1,
          description: "Payment",
          actionar_type: "specific_department",
          role_key: "finance"
        }
      ]
    }
  end

  test "set_active_registration_flow deactivates the previous active workflow" do
    active_workflow_fixture()

    {:ok, flow_a} = Workflows.create_registration_flow(flow_attrs("Flow A", true))
    {:ok, flow_b} = Workflows.create_registration_flow(flow_attrs("Flow B", false))

    assert Workflows.get_active_registration_flow().id == flow_a.id

    assert {:ok, activated} = Workflows.set_active_registration_flow(flow_b.id)
    assert activated.id == flow_b.id
    assert activated.is_active

    reloaded_a = Workflows.get_registration_flow!(flow_a.id)
    refute reloaded_a.is_active
    assert Workflows.get_active_registration_flow().id == flow_b.id
  end

  test "creating a flow as active turns off the previous active one" do
    active_workflow_fixture()

    {:ok, flow_a} = Workflows.create_registration_flow(flow_attrs("Flow A", true))
    {:ok, flow_b} = Workflows.create_registration_flow(flow_attrs("Flow B", true))

    assert flow_b.is_active
    refute Workflows.get_registration_flow!(flow_a.id).is_active
    assert Workflows.get_active_registration_flow().id == flow_b.id
  end

  test "new registrations attach to the currently active workflow" do
    active_workflow_fixture()

    {:ok, flow_a} = Workflows.create_registration_flow(flow_attrs("Flow A", true))
    registration_a = registration_fixture()
    assert registration_a.workflow_id == flow_a.id

    {:ok, flow_b} = Workflows.create_registration_flow(flow_attrs("Flow B", true))

    registration_b =
      registration_fixture(%{tracking_number: "REG-switch-#{System.unique_integer([:positive])}"})

    assert registration_b.workflow_id == flow_b.id
    assert registration_a.workflow_id == flow_a.id
  end
end
