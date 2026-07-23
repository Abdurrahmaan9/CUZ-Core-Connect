defmodule CuzCoreConnect.Communications.Seeds do
  @moduledoc false

  alias CuzCoreConnect.Communications

  def plant do
    if Communications.list_announcements() == [] do
      {:ok, _} =
        Communications.create_announcement(%{
          title: "Semester Registration Now Open",
          body:
            "Registration for the upcoming semester is open. Complete your course selection and payment by the deadline.",
          audience: "All Students",
          author: "Academic Office",
          status: "published"
        })

      IO.puts("✅ Seeded sample published announcement")
    else
      IO.puts("ℹ️  Announcements already present")
    end
  end
end
