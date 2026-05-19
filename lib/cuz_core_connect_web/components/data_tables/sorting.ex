defmodule CuzCoreConnectWeb.Utilities.Sorting do
  @moduledoc """
  Utility module for handling table sorting URL parameters.
  """

  @doc """
  Encodes a table link URL with sorting parameters.
  """
  def table_link_encode_url(filter_params, filter_item) do
    current_sort_order = Map.get(filter_params, "sort_order", "asc")
    current_sort_column = Map.get(filter_params, "sort_column", "")

    new_sort_order =
      if current_sort_column == filter_item do
        if current_sort_order == "asc", do: "desc", else: "asc"
      else
        "asc"
      end

    filter_params
    |> Map.put("sort_column", filter_item)
    |> Map.put("sort_order", new_sort_order)
    |> URI.encode_query()
    |> then(fn query -> "?#{query}" end)
  end
end
