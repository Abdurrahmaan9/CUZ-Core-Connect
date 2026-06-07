defmodule CuzCoreConnect.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(admin academics finance hod student retention)
  @default_actions ~w(view)

  schema "tbl_pages" do
    field :name, :string
    field :description, :string
    field :role, :string, default: "admin"
    field :paths, {:array, :string}, default: []
    field :actions, {:array, :string}, default: @default_actions
    field :deleted_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:name, :description, :role, :paths, :actions])
    |> validate_required([:name, :role])
    |> validate_inclusion(:role, @roles)
  end

  def roles, do: @roles
  def default_actions, do: @default_actions
end
