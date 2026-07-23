defmodule CuzCoreConnect.Academics.Courses do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_courses" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :credits, :integer, default: 3
    field :is_active, :boolean, default: true

    # Virtual fields used when creating a course assigned to a programme
    field :program_id, :id, virtual: true
    field :year, :integer, virtual: true
    field :semester, :integer, virtual: true
    field :is_core, :boolean, virtual: true, default: false

    has_many :program_courses, CuzCoreConnect.Academics.ProgramCourse, foreign_key: :course_id
    timestamps()
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [
      :title,
      :description,
      :code,
      :credits,
      :is_active,
      :program_id,
      :year,
      :semester,
      :is_core
    ])
    |> validate_required([:title, :code, :credits])
    |> unique_constraint(:code)
  end

  @doc """
  Changeset for creating a course that must be linked to a programme.
  """
  def create_with_program_changeset(course, attrs) do
    course
    |> changeset(attrs)
    |> validate_required([:program_id, :year, :semester])
    |> validate_number(:year, greater_than: 0)
    |> validate_inclusion(:semester, [1, 2])
  end
end
