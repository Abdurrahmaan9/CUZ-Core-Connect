defmodule CuzCoreConnect.Academic do
  @moduledoc """
  The Academic context handles program, course, and student relationships.
  """
  import Ecto.Query, warn: false
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Academics.Programs, as: Program
  alias CuzCoreConnect.Academic.ProgramCourse
  alias CuzCoreConnect.Academic.StudentProgram
  alias CuzCoreConnect.Academic.LecturerCourse
  alias CuzCoreConnect.Academic.LecturerProgram
  alias CuzCoreConnect.Academics.Courses, as: Course
  alias CuzCoreConnect.Accounts.User

  # ====================== Program functions =================================
  def list_programs do
    Repo.all(Program)
  end

  def get_program!(id), do: Repo.get!(Program, id)

  def create_program(attrs \\ %{}) do
    %Program{}
    |> Program.changeset(attrs)
    |> Repo.insert()
  end

  def update_program(%Program{} = program, attrs) do
    program
    |> Program.changeset(attrs)
    |> Repo.update()
  end

  def delete_program(%Program{} = program) do
    Repo.delete(program)
  end

  def change_program(%Program{} = program, attrs \\ %{}) do
    Program.changeset(program, attrs)
  end

  # Program Course functions
  def list_program_courses(program_id) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id,
      preload: [:course],
      order_by: [asc: :year, asc: :semester, asc: :id]
    )
    |> Repo.all()
  end

  def get_program_course!(id), do: Repo.get!(ProgramCourse, id)

  def create_program_course(attrs \\ %{}) do
    %ProgramCourse{}
    |> ProgramCourse.changeset(attrs)
    |> Repo.insert()
  end

  def update_program_course(%ProgramCourse{} = program_course, attrs) do
    program_course
    |> ProgramCourse.changeset(attrs)
    |> Repo.update()
  end

  def delete_program_course(%ProgramCourse{} = program_course) do
    Repo.delete(program_course)
  end

  def change_program_course(%ProgramCourse{} = program_course, attrs \\ %{}) do
    ProgramCourse.changeset(program_course, attrs)
  end

  # Helper functions
  def list_courses_not_in_program(program_id) do
    # First, get all course IDs that are already in the program
    assigned_course_ids =
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        select: pc.course_id
      )
      |> Repo.all()

    # Then find all courses that are not in the assigned_course_ids list
    from(c in Course,
      where: c.id not in ^assigned_course_ids
    )
    |> Repo.all()
  end




  @doc """
  Lists all programs for a specific lecturer.
  """
  def list_lecturer_programs(user_id) do
    from(up in Register.Academic.LecturerProgram,
      where: up.user_id == ^user_id,
      preload: [:program],
      order_by: [desc: :is_primary, asc: :id]
    )
    |> Repo.all()
    |> Enum.map(& &1.program)
  end

  @doc """
  Lists all courses for a specific lecturer in a specific program.
  """
  def list_lecturer_courses(user_id, program_id) do
    # First, get all program courses for the given program
    program_courses =
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        preload: [:course],
        order_by: [asc: :year, asc: :semester, asc: :id]
      )
      |> Repo.all()

    # In a real application, you might want to filter these based on the lecturer's permissions
    # For now, we'll return all courses in the program
    Enum.map(program_courses, & &1.course)
  end

  @doc """
  Assigns a program to a lecturer.
  """
  # def assign_lecturer_to_program(user_id, program_id, attrs \\ %{}) do
  #   %Register.Academic.LecturerProgram{}
  #   |> Register.Academic.LecturerProgram.changeset(
  #     Map.merge(%{user_id: user_id, program_id: program_id}, attrs)
  #   )
  #   |> Repo.insert()
  # end

  @doc """
  Removes a program assignment from a lecturer.
  """
  # def remove_lecturer_from_program(user_id, program_id) do
  #   from(lp in LecturerProgram, where: lp.user_id == ^user_id and lp.program_id == ^program_id)
  #   |> Repo.delete_all()
  #   :ok
  # end

  @doc """
  Lists all lecturers with their assigned programs.
  """
  # def list_lecturers_with_programs do
  #   from(u in Register.Accounts.User,
  #     where: u.role == "lecturer",
  #     left_join: lp in assoc(u, :lecturer_programs),
  #     left_join: p in assoc(lp, :program),
  #     preload: [lecturer_programs: {lp, program: p}],
  #     order_by: [asc: u.last_name, asc: u.first_name]
  #   )
  #   |> Repo.all()
  # end

  @doc """
  Gets a lecturer with their assigned programs.
  """
  def get_lecturer_with_programs(user_id) do
    from(u in Register.Accounts.User,
      where: u.id == ^user_id and u.role == "lecturer",
      left_join: lp in assoc(u, :lecturer_programs),
      left_join: p in assoc(lp, :program),
      preload: [lecturer_programs: {lp, program: p}]
    )
    |> Repo.one()
  end

  @doc """
  Lists all programs not assigned to a lecturer.
  """
  def list_unassigned_programs(user_id) do
    assigned_program_ids =
      from(lp in LecturerProgram,
        where: lp.user_id == ^user_id,
        select: lp.program_id
      )
      |> Repo.all()

    from(p in Program,
      where: p.id not in ^assigned_program_ids,
      order_by: [asc: :name]
    )
    |> Repo.all()
  end

  def get_courses_by_program_and_semester(program_id, year, semester) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id and pc.year == ^year and pc.semester == ^semester,
      preload: [:course],
      order_by: [asc: :is_core, asc: :id]
    )
    |> Repo.all()
  end

  # ===================== Student Program functions ==================================
  # def list_student_programs(student_id) do
  #   from(sp in StudentProgram,
  #     where: sp.student_id == ^student_id,
  #     preload: [:program],
  #     order_by: [desc: :is_active, desc: :enrollment_date]
  #   )
  #   |> Repo.all()
  # end

  # def list_students_in_program(program_id) do
  #   from(sp in StudentProgram,
  #     join: u in User, on: u.id == sp.student_id,
  #     where: sp.program_id == ^program_id and sp.is_active == true,
  #     preload: [:student],
  #     order_by: [asc: u.email]
  #   )
  #   |> Repo.all()
  # end

  # def get_student_program!(id), do: Repo.get!(StudentProgram, id) |> Repo.preload([:student, :program])

  # def create_student_program(attrs \\ %{}) do
  #   %StudentProgram{}
  #   |> StudentProgram.changeset(attrs)
  #   |> Repo.insert()
  # end

  # def update_student_program(%StudentProgram{} = student_program, attrs) do
  #   student_program
  #   |> StudentProgram.changeset(attrs)
  #   |> Repo.update()
  # end

  # def delete_student_program(%StudentProgram{} = student_program) do
  #   Repo.delete(student_program)
  # end

  # def change_student_program(%StudentProgram{} = student_program, attrs \\ %{}) do
  #   StudentProgram.changeset(student_program, attrs)
  # end

  # @doc """
  # Returns all active courses assigned to a student through their active program enrollments
  # """
  # def list_student_courses(student_id) do
  #   from(sp in StudentProgram,
  #     join: pc in ProgramCourse,
  #     on:
  #       pc.program_id == sp.program_id and
  #         pc.semester == sp.semester,
  #     join: p in Program, on: p.id == sp.program_id,
  #     join: c in Course, on: c.id == pc.course_id,
  #     where:
  #       sp.student_id == ^student_id and
  #         sp.is_active == true and
  #         pc.is_active == true and
  #         c.is_active == true,
  #     order_by: [asc: pc.year, asc: pc.semester, asc: c.code],
  #     select: %{
  #       course: c,
  #       year: pc.year,
  #       semester: pc.semester,
  #       program: p,
  #       academic_year: sp.academic_year
  #     }
  #   )
  #   |> Repo.all()
  # end

  # @doc """
  #   Returns all active courses assigned to a student through their active program enrollments
  #   including courses from other semesters
  # """
  # def list_all_student_courses(student_id) do
  #   from(sp in StudentProgram,
  #     join: pc in ProgramCourse,
  #     on: pc.program_id == sp.program_id,
  #     join: p in Program, on: p.id == sp.program_id,
  #     join: c in Course, on: c.id == pc.course_id,
  #     where:
  #       sp.student_id == ^student_id and
  #       pc.is_active == true and
  #       c.is_active == true,
  #     order_by: [asc: pc.year, asc: pc.semester, asc: c.code],
  #     select: %{
  #       course: c,
  #       year: pc.year,
  #       semester: pc.semester,
  #       program: p,
  #       academic_year: sp.academic_year
  #     }
  #   )
  #   |> Repo.all()
  # end



  # ===================== LECTURER COURSES =====================

  # def list_lecturers_with_courses do
  #   from(u in User,
  #     where: u.role == "lecturer",
  #     preload: [lecturer_courses: :course]
  #   )
  #   |> Repo.all()
  # end

  # def get_lecturer_with_courses(user_id) do
  #   from(u in User,
  #     where: u.id == ^user_id and u.role == "lecturer",
  #     preload: [lecturer_courses: :course]
  #   )
  #   |> Repo.one()
  # end

  # def list_unassigned_courses(user_id) do
  #   # Get all courses not assigned to this lecturer
  #   assigned_course_ids =
  #     from(lc in LecturerCourse,
  #       where: lc.user_id == ^user_id,
  #       select: lc.course_id
  #     )
  #     |> Repo.all()

  #   from(c in Course,
  #     where: c.id not in ^assigned_course_ids
  #   )
  #   |> Repo.all()
  # end

  # def assign_lecturer_to_course(user_id, course_id) do
  #   %LecturerCourse{}
  #   |> LecturerCourse.changeset(%{
  #     user_id: user_id,
  #     course_id: course_id,
  #     is_primary: false
  #   })
  #   |> Repo.insert()
  # end

  # def remove_lecturer_from_course(user_id, course_id) do
  #   from(lc in LecturerCourse,
  #     where: lc.user_id == ^user_id and lc.course_id == ^course_id
  #   )
  #   |> Repo.delete_all()
  #   |> case do
  #     {1, _} -> :ok
  #     _ -> {:error, :not_found}
  #   end
  # end

  # @doc """
  # Lists all courses for a specific lecturer in a specific program.
  # """
  # @doc """
  # Lists all courses assigned to a specific lecturer.
  # """
  # def list_lecturer_courses(user_id) do
  #   from(lc in LecturerCourse,
  #     where: lc.user_id == ^user_id,
  #     preload: [:course],
  #     order_by: [desc: :is_primary, asc: :id]
  #   )
  #   |> Repo.all()
  #   |> Enum.map(& &1.course)
  # end

  # def list_unassigned_courses(user_id) do
  #   # Get all courses not assigned to this lecturer
  #   assigned_course_ids =
  #     from(lc in LecturerCourse,
  #       where: lc.user_id == ^user_id,
  #       select: lc.course_id
  #     )
  #     |> Repo.all()

  #   from(c in Course,
  #     where: c.id not in ^assigned_course_ids
  #   )
  #   |> Repo.all()
  # end


  # ======================= Course Functions ==================================
  @doc """
  Returns the list of courses.

  ## Examples

      iex> list_courses()
      [%Course{}, ...]

  """
  def list_courses do
    from(c in Course, where: c.is_active == true, order_by: [asc: :code])
    |> Repo.all()
  end

  @doc """
  Lists all courses including inactive ones.
  """
  def list_all_courses do
    from(c in Course, order_by: [asc: :code])
    |> Repo.all()
  end

  @doc """
  Gets a single course.

  Raises `Ecto.NoResultsError` if the Course does not exist.

  ## Examples

      iex> get_course!(123)
      %Course{}

      iex> get_course!(456)
      ** (Ecto.NoResultsError)

  """
  def get_course!(id) do
    Course
    |> Repo.get!(id)
    |> Repo.preload([:programs, program_courses: :program])
  end

  @doc """
  Creates a course.

  ## Examples

      iex> create_course(%{field: value})
      {:ok, %Course{}}

      iex> create_course(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_course(attrs \\ %{}) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a course.

  ## Examples

      iex> update_course(course, %{field: new_value})
      {:ok, %Course{}}

      iex> update_course(course, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_course(%Course{} = course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a course.

  ## Examples

      iex> delete_course(course)
      {:ok, %Course{}}

      iex> delete_course(course)
      {:error, %Ecto.Changeset{}}

  """
  def delete_course(%Course{} = course) do
    Repo.delete(course)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course changes.

  ## Examples

      iex> change_course(course)
      %Ecto.Changeset{data: %Course{}}

  """
  def change_course(%Course{} = course, attrs \\ %{}) do
    Course.changeset(course, attrs)
  end

  @doc """
  Lists courses not assigned to a specific program.
  """
  def list_available_courses(program_id) do
    assigned_course_ids =
      from(pc in ProgramCourse,
        where: pc.program_id == ^program_id,
        select: pc.course_id
      )
      |> Repo.all()

    from(c in Course,
      where: c.id not in ^assigned_course_ids,
      where: c.is_active == true,
      order_by: [asc: :code]
    )
    |> Repo.all()
  end

  @doc """
  Gets courses by program, year, and semester.
  """
  def get_courses_by_program_and_semester(program_id, year, semester) do
    from(pc in ProgramCourse,
      where: pc.program_id == ^program_id and pc.year == ^year and pc.semester == ^semester,
      where: pc.is_active == true,
      preload: [:course],
      order_by: [asc: :is_core, asc: :id]
    )
    |> Repo.all()
    |> Enum.map(fn pc -> %{pc.course | program_course_id: pc.id, is_core: pc.is_core} end)
  end

  @doc """
  Returns the total count of courses.

  ## Examples

      iex> count_courses()
      5

  """
  def count_courses do
    Repo.aggregate(Course, :count, :id)
  end
end
