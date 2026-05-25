defmodule CuzCoreConnect.LocalTimestamp do
  @moduledoc "Custom Ecto timestamp module for local time in Africa/Lusaka"

  def autogenerate, do: now()
  def autogenerate(_), do: now()

  def now do
    DateTime.now!("Africa/Lusaka") |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  end
end
