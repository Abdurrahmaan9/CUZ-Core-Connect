defmodule CuzCoreConnect.Scholarships.Seeds do
  @moduledoc false

  alias CuzCoreConnect.Scholarships

  def plant do
    if Scholarships.list_scholarships() == [] do
      samples = [
        %{
          name: "Presidential Scholarship",
          code: "PRES-FULL",
          sponsor: "CUZ Foundation",
          coverage: "full",
          description: "Full tuition coverage for outstanding academic performance.",
          status: "active"
        },
        %{
          name: "Need-Based Bursary",
          code: "NEED-PART",
          sponsor: "Student Affairs",
          coverage: "partial",
          description: "Partial fee support for students with demonstrated financial need.",
          status: "active"
        },
        %{
          name: "Staff Dependent Tuition Waiver",
          code: "STAFF-TUIT",
          sponsor: "Human Resources",
          coverage: "tuition_only",
          description: "Tuition waiver for dependents of university staff.",
          status: "active"
        }
      ]

      Enum.each(samples, fn attrs ->
        {:ok, _} = Scholarships.create_scholarship(attrs)
      end)

      IO.puts("✅ Seeded sample scholarships")
    else
      IO.puts("ℹ️  Scholarships already present")
    end
  end
end
