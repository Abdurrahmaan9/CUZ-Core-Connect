defmodule CuzCoreConnect.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_pages" do
    field :name, :string
    field :paths, {:array, :string}, default: []
    field :actions, {:array, :string}, default: ["view", "create", "edit", "export", "delete"]
    field :description, :string
    field :is_admin, :boolean, default: false
    field :is_deleted, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:description, :is_admin, :name, :paths, :is_deleted, :actions])
  end
end
