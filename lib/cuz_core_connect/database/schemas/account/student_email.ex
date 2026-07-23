defmodule CuzCoreConnect.Accounts.StudentEmail do
  @moduledoc """
  Institutional student email helpers.

  Suggested format:
  `<first initial><last initial><student number>@students.cavendish.co.zm`
  """

  @domain "students.cavendish.co.zm"
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  def domain, do: @domain

  @doc """
  Builds the suggested institutional email, or `nil` when inputs are incomplete.
  """
  def suggest(first_name, last_name, student_number) do
    fi = initial(first_name)
    li = initial(last_name)
    number = normalize_student_number(student_number)

    if fi != "" and li != "" and number != "" do
      String.downcase("#{fi}#{li}#{number}@#{@domain}")
    end
  end

  def valid_format?(email) when is_binary(email) do
    email = String.trim(email)
    email != "" and Regex.match?(@email_regex, email) and String.length(email) <= 160
  end

  def valid_format?(_), do: false

  def valid_student_number?(number) when is_binary(number) do
    Regex.match?(~r/^\d{6,}$/, String.trim(number))
  end

  def valid_student_number?(_), do: false

  def normalize_student_number(nil), do: ""

  def normalize_student_number(number) do
    number
    |> to_string()
    |> String.trim()
  end

  defp initial(name) do
    name
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z]/, "")
    |> case do
      "" -> ""
      cleaned -> String.first(cleaned)
    end
  end
end
