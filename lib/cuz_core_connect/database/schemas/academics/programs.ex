defmodule CuzCoreConnect.Academics.Programs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_programs" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :duration_years, :integer, default: 4
    field :is_active, :boolean, default: true

    has_many :program_courses, CuzCoreConnect.Academic.ProgramCourse
    has_many :courses, through: [:program_courses, :course]


    timestamps()
  end

  @doc false
  def changeset(program, attrs) do
    program
    |> cast(attrs, [:name, :code, :description, :duration_years, :is_active])
    |> validate_required([:name, :code])
    |> unique_constraint(:code)
  end

end
