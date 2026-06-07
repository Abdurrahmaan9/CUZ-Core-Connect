defmodule CuzCoreConnect.NotifySubs do
  @moduledoc false

  def notify_subs({:ok, result}), do: {:ok, result}
  def notify_subs({:error, result}), do: {:error, traverse_errors(result.errors)}

  def notify_subs({:error, _failed_operation, failed_value, _changes_so_far}),
    do: {:error, traverse_errors(failed_value.errors)}

  def traverse_errors(errors),
    do:
      errors
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Enum.map(fn {key, {msg, _}} -> "#{key} #{msg}" end)
      |> List.first()
end
