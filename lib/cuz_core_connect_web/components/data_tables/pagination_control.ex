defmodule CuzCoreConnectWeb.Helps.PaginationControl do
  @moduledoc false
  use CuzCoreConnectWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""

    """
  end

  def order_by_composer(socket, params \\ %{"sort_direction" => "desc", "sort_field" => "id"}) do
    if params["sort_direction"],
      do:
        assign(socket,
          order_by: %{
            "sort_direction" => params["sort_direction"],
            "sort_field" => params["sort_field"]
          }
        ),
      else: socket
  end

  def i_search_composer(socket, params \\ %{"isearch" => ""}) do
    if params["isearch"],
      do: assign(socket, isearch: %{"isearch" => params["isearch"]}),
      else: socket
  end

  def create_table_params(%{assigns: assigns} = _socket, params) do
    # Merge socket assigns params with current incoming params
    # This ensures sort_field/direction are preserved
    merged_params = Map.merge(assigns.params || %{}, params)

    # Standardize filter structure. We want everything and isearch inside "filter"
    filter_data =
      (merged_params["filter"] || %{})
      |> Map.merge(assigns.isearch || %{})

    Map.put(merged_params, "filter", filter_data)
    |> Map.merge(%{"order_by" => assigns.order_by})
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
end
