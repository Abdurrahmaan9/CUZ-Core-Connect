defmodule CuzCoreConnect.Academics.Programmes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_programmes" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :duration_years, :integer, default: 4
    field :is_active, :boolean, default: true

    has_many :program_courses, CuzCoreConnect.Academics.ProgramCourse, foreign_key: :program_id


    timestamps()
  end

  @doc false
  def changeset(programme, attrs) do
    programme
    |> cast(attrs, [:name, :code, :description, :duration_years, :is_active])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end

end
