defmodule CuzCoreConnectWeb.Datatable.Pagination do
  @moduledoc false
  use CuzCoreConnectWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    """
  end

  def param_value(params, key, default) do
    value =
      cond do
        is_map(params) && Map.has_key?(params, key) && Map.get(params, key) not in [nil, ""] ->
          Map.get(params, key)

        is_map(params) && Map.has_key?(params, to_string(key)) &&
            Map.get(params, to_string(key)) not in [nil, ""] ->
          Map.get(params, to_string(key))

        true ->
          default
      end

    case value do
      val when is_binary(val) -> String.to_integer(val)
      val when is_integer(val) -> val
      _ -> default
    end
  end

  def do_paginate(query, params) do
    try do
      with %{} = result <- CuzCoreConnect.Repo.paginate(query, params),
           true <- Map.has_key?(result, :page_number) do
        {:ok, result}
      else
        _ -> {:error, :invalid_pagination}
      end
    rescue
      e -> {:error, e}
    end
  end

  def empty_page_result do
    %{
      entries: [],
      page_number: 1,
      page_size: 10,
      total_entries: 0,
      total_pages: 0
    }
  end

  def boolean_status_ui(status) do
    if status == true,
      do: """
      <span class="badge badge-success badge-pill"> Active </span>
      """

    if status == false,
      do: """
        <span class="badge badge-danger badge-pill"> Disabled </span>
      """

    if status == nil, do: "
      <span class='badge badge-danger badge-pill'> Pending Approval </span>
    "
  end

  @doc """
  Assigns filter params to socket from URL params.
  Reads filter keys dynamically from socket.assigns[:filter_keys].
  Call this in handle_params to restore filters from URL.
  """
  def filter_composer(socket, params) do
    filter_keys = Map.get(socket.assigns, :filter_keys, [])

    Enum.reduce(filter_keys, socket, fn key, acc_socket ->
      string_key = to_string(key)
      value = Map.get(params, string_key, "")
      assign(acc_socket, key, value)
    end)
  end

  # @doc """
  # Builds a query string from current socket assigns for the given filter keys.
  # Use this with push_patch to encode filters in the URL.
  # """
  # def build_filter_params(socket, filter_keys) do
  #   filter_keys
  #   |> Enum.reduce(%{}, fn key, acc ->
  #     value = socket.assigns[key]
  #     if value && value != "", do: Map.put(acc, to_string(key), value), else: acc
  #   end)
  # end

  @doc """
  Pushes current filters + page to URL via push_patch.
  Reads filter keys dynamically from socket.assigns[:filter_keys],
  with pagination/sort keys always included.
  """
  def push_filters(socket, path, extra_params \\ %{}) do
    dynamic_keys = Map.get(socket.assigns, :filter_keys, [])
    always_keys = [:page, :sort_field, :sort_direction]
    all_keys = Enum.uniq(dynamic_keys ++ always_keys)

    filter_params =
      socket.assigns
      |> Map.take(all_keys)
      |> Enum.reject(fn {_, v} -> is_nil(v) or v == "" end)
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.merge(extra_params)

    Phoenix.LiveView.push_patch(socket, to: path <> "?" <> URI.encode_query(filter_params))
  end

  @doc """
  Assigns all filter keys from a map of %{key => default_value} and stores
  the keys list in :filter_keys for push_filters to use dynamically.
  """
  def assign_filters(socket, filter_map) do
    socket
    |> assign(:filter_keys, Map.keys(filter_map))
    |> then(fn s ->
      Enum.reduce(filter_map, s, fn {key, default}, acc ->
        assign(acc, key, default)
      end)
    end)
  end

  @doc """
  Returns a map of current filter values from socket assigns.
  Reads keys dynamically from socket.assigns[:filter_keys].
  """
  def fetch_current_filters(socket) do
    filter_keys = Map.get(socket.assigns, :filter_keys, [])
    Map.take(socket.assigns, filter_keys)
  end

  @doc """
  Builds a string-keyed map of current non-empty filter values + page,
  suitable for use in URL query params.
  """
  def build_current_params(assigns) do
    filter_keys = Map.get(assigns, :filter_keys, [])
    always_keys = [:page, :sort_field, :sort_direction]
    all_keys = Enum.uniq(filter_keys ++ always_keys)

    assigns
    |> Map.take(all_keys)
    |> Enum.reject(fn {_, v} -> is_nil(v) or v == "" end)
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
  end
end
