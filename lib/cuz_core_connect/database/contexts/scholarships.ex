defmodule CuzCoreConnect.Scholarships do
  @moduledoc """
  Admin-maintainable scholarships that students can select during registration
  when they are funded by a scholarship instead of (or in addition to) paying.
  """

  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Scholarships.Scholarship

  def list_scholarships do
    Scholarship
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  def list_scholarships_by_status(status) when status in ~w(active inactive) do
    Scholarship
    |> where([s], s.status == ^status)
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  def list_active_scholarships do
    list_scholarships_by_status("active")
  end

  def get_scholarship!(id), do: Repo.get!(Scholarship, id)

  def get_scholarship(id) when is_integer(id), do: Repo.get(Scholarship, id)
  def get_scholarship(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> Repo.get(Scholarship, int)
      :error -> nil
    end
  end

  def get_scholarship(_), do: nil

  def create_scholarship(attrs \\ %{}) do
    %Scholarship{}
    |> Scholarship.changeset(attrs)
    |> Repo.insert()
  end

  def update_scholarship(%Scholarship{} = scholarship, attrs) do
    scholarship
    |> Scholarship.changeset(attrs)
    |> Repo.update()
  end

  def delete_scholarship(%Scholarship{} = scholarship) do
    Repo.delete(scholarship)
  end

  def change_scholarship(%Scholarship{} = scholarship, attrs \\ %{}) do
    Scholarship.changeset(scholarship, attrs)
  end

  def scholarship_stats do
    rows =
      from(s in Scholarship,
        group_by: s.status,
        select: {s.status, count(s.id)}
      )
      |> Repo.all()
      |> Map.new()

    total = Map.values(rows) |> Enum.sum()

    %{
      total: total,
      active: Map.get(rows, "active", 0),
      inactive: Map.get(rows, "inactive", 0)
    }
  end

  def scholarship_options(scholarships \\ list_active_scholarships()) do
    Enum.map(scholarships, fn s ->
      label =
        cond do
          is_binary(s.code) and s.code != "" -> "#{s.name} (#{s.code})"
          true -> s.name
        end

      {label, s.id}
    end)
  end
end
