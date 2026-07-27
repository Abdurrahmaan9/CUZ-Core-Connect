defmodule CuzCoreConnect.ScholarshipsTest do
  use CuzCoreConnect.DataCase, async: true

  alias CuzCoreConnect.Scholarships

  test "creates and lists active scholarships for registration dropdown" do
    assert {:ok, scholarship} =
             Scholarships.create_scholarship(%{
               name: "Test Grant",
               code: "TEST-#{System.unique_integer()}",
               coverage: "full",
               status: "active"
             })

    assert scholarship.name == "Test Grant"
    assert Enum.any?(Scholarships.list_active_scholarships(), &(&1.id == scholarship.id))
    assert Enum.any?(Scholarships.scholarship_options(), fn {_label, id} -> id == scholarship.id end)
  end

  test "inactive scholarships are hidden from active list" do
    {:ok, scholarship} =
      Scholarships.create_scholarship(%{
        name: "Paused Grant",
        code: "PAUSE-#{System.unique_integer()}",
        status: "inactive"
      })

    refute Enum.any?(Scholarships.list_active_scholarships(), &(&1.id == scholarship.id))
  end
end
