defmodule CuzCoreConnect.LocalTimestamp do
  @moduledoc """
  Custom Ecto timestamp module for local time in Africa/Lusaka (UTC+2, no DST).

  Uses a fixed offset so it works without a timezone database (`:utc_only_time_zone_database`).
  """

  # Africa/Lusaka observes Central Africa Time (UTC+2) year-round.
  @lusaka_offset_seconds 2 * 60 * 60

  def autogenerate, do: now()
  def autogenerate(_), do: now()

  def now do
    DateTime.utc_now()
    |> DateTime.add(@lusaka_offset_seconds, :second)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end
end
