defmodule CuzCoreConnectWeb.CertificateHTML do
  use CuzCoreConnectWeb, :html

  embed_templates "certificate_html/*"

  def programme(registration) do
    get_in(registration.student_program_details, ["program_name"]) || "—"
  end

  def academic_year(registration) do
    get_in(registration.student_program_details, ["academic_year"]) || "—"
  end

  def semester(registration) do
    get_in(registration.student_program_details, ["semester"]) || "—"
  end

  def intake(registration) do
    case get_in(registration.student_program_details, ["intake"]) do
      nil -> nil
      "" -> nil
      value -> value
    end
  end

  def selected_courses(registration) do
    get_in(registration.student_courses, ["selected_courses"]) || []
  end

  def total_credits(registration) do
    stored = get_in(registration.student_courses, ["total_credit_hours"])

    cond do
      is_integer(stored) ->
        stored

      is_binary(stored) ->
        case Integer.parse(stored) do
          {n, _} -> n
          :error -> sum_course_credits(selected_courses(registration))
        end

      true ->
        sum_course_credits(selected_courses(registration))
    end
  end

  def course_code(course), do: course["code"] || course[:code]
  def course_name(course), do: course["name"] || course[:name]
  def course_credits(course), do: course["credits"] || course[:credits] || "—"

  def academic_period(registration) do
    base = "#{academic_year(registration)} · #{semester(registration)}"

    case intake(registration) do
      nil -> base
      value -> "#{base} · #{value}"
    end
  end

  defp sum_course_credits(courses) do
    Enum.reduce(courses, 0, fn course, acc ->
      case course["credits"] || course[:credits] do
        n when is_integer(n) ->
          acc + n

        n when is_float(n) ->
          acc + trunc(n)

        n when is_binary(n) ->
          case Integer.parse(n) do
            {i, _} -> acc + i
            :error -> acc
          end

        _ ->
          acc
      end
    end)
  end
end
