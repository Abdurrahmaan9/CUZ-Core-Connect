defmodule CuzCoreConnect.Scholarships.Scholarship do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(active inactive)
  @coverages ~w(full partial tuition_only other)

  schema "tbl_scholarships" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :sponsor, :string
    field :coverage, :string, default: "full"
    field :status, :string, default: "active"

    timestamps(type: :utc_datetime)
  end

  def changeset(scholarship, attrs) do
    scholarship
    |> cast(attrs, [:name, :code, :description, :sponsor, :coverage, :status])
    |> validate_required([:name, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:coverage, @coverages)
    |> update_change(:code, &blank_to_nil/1)
    |> unique_constraint(:code)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
