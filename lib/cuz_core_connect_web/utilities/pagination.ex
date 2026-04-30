defmodule CuzCoreConnectWeb.Utilities.Pagination do
  @moduledoc """
  Utility module for handling table pagination links.
  """

  @doc """
  Gets the previous page pagination link.
  """
  def get_priv_pagination_link(pagination, filter_params) do
    new_params = Map.put(filter_params, "page_number", pagination.page_number - 1)
    "?#{URI.encode_query(new_params)}"
  end

  @doc """
  Gets the next page pagination link.
  """
  def get_next_pagination_link(pagination, filter_params) do
    new_params = Map.put(filter_params, "page_number", pagination.page_number + 1)
    "?#{URI.encode_query(new_params)}"
  end

  @doc """
  Gets a specific page number pagination link.
  """
  def get_number_pagination_link(page_number, filter_params) do
    new_params = Map.put(filter_params, "page_number", page_number)
    "?#{URI.encode_query(new_params)}"
  end
end
