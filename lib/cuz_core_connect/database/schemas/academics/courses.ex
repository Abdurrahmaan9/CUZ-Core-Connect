defmodule CuzCoreConnect.Academics.Courses do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_courses" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :credits, :integer, default: 3
    field :is_active, :boolean, default: true

    has_many :program_courses, CuzCoreConnect.Academics.ProgramCourse, foreign_key: :course_id
    timestamps()
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:title, :description, :code, :credits, :is_active])
    |> validate_required([:title, :code, :credits])
    |> unique_constraint(:code)
  end
end
