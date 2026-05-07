defmodule CuzCoreConnect.Academics.ProgramCourse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_program_courses" do
    field :year, :integer
    field :semester, :integer
    field :is_core, :boolean, default: false
    field :is_active, :boolean, default: true

    belongs_to :program, CuzCoreConnect.Academics.Programs, foreign_key: :program_id
    belongs_to :course, CuzCoreConnect.Academics.Courses, foreign_key: :course_id

    timestamps()
  end

  @doc false
  def changeset(program_course, attrs) do
    program_course
    |> cast(attrs, [:program_id, :course_id, :year, :semester, :is_core, :is_active])
    |> validate_required([:program_id, :course_id, :year, :semester])
    |> unique_constraint([:program_id, :course_id, :year, :semester])
    |> foreign_key_constraint(:program_id)
    |> foreign_key_constraint(:course_id)
  end
end
