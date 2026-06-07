defmodule CuzCoreConnect.Workflows do
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnectWeb.Pagination
  alias CuzCoreConnect.Workflows.RegistrationWorkflow

  def list_registration_flows do
    from(mf in RegistrationWorkflow,
      where: mf.is_deleted == false,
      order_by: [asc: mf.name]
    )
    |> Repo.all()
  end

  def list_peginated_registration_flows(params \\ %{page: 1, page_size: 10}, filters \\ %{}) do
    page_params = %{
      page: Pagination.param_value(params, :page, 1),
      page_size: Pagination.param_value(params, :page_size, 10)
    }

    query =
      RegistrationWorkflow
      |> where([f], is_nil(f.deleted_at))
      |> apply_filters(filters)
      |> order_by(desc: :updated_at)

    case Pagination.do_paginate(query, page_params) do
      {:ok, page} ->
        page

      {:error, _reason} ->
        %{
          entries: [],
          page_number: 1,
          page_size: 10,
          total_entries: 0,
          total_pages: 0
        }
    end
  end

  def get_registration_flows(id) do
    RegistrationWorkflow
    |> where([mf], mf.id == ^id)
    # |> preload([:stages])
    |> Repo.one()
  end

  def list_flows do
    from(mf in RegistrationWorkflow,
      order_by: [asc: mf.name]
    )
    |> Repo.all()
  end

  def registration_flow_changeset(registration_flow \\ %RegistrationWorkflow{}, attrs \\ %{}) do
    RegistrationWorkflow.changeset(registration_flow, attrs)
  end

  def update_registration_flow(%RegistrationWorkflow{} = registration_flow, attrs) do
    RegistrationWorkflow.changeset(registration_flow, attrs)
    |> Repo.update()
  end

  def get_registration_flow!(id), do: Repo.get!(RegistrationWorkflow, id)

  def get_registration_flows_by_id(id) do
    RegistrationWorkflow
    |> where([mf], mf.id == ^id)
    |> Repo.one()
  end

  def create_registration_flow(attrs) do
    RegistrationWorkflow.changeset(%RegistrationWorkflow{}, attrs)
    |> Repo.insert()
  end

  def get_registration_flows_changeset(registration_flow \\ %RegistrationWorkflow{}, attrs \\ %{}) do
    RegistrationWorkflow.changeset(registration_flow, attrs)
  end

  # helpers to pick sensible timestamps from lists of structs
  def get_first_inserted_at(list) when is_list(list) and list != [] do
    list
    |> Enum.map(&Map.get(&1, :inserted_at))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  def get_first_inserted_at(_), do: nil

  def get_last_updated_at(list) when is_list(list) and list != [] do
    list
    |> Enum.map(&Map.get(&1, :updated_at))
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> nil end)
  end

  def get_last_updated_at(_), do: nil

  defp apply_filters(query, filters) do
    query
    |> maybe_search(filters[:search_filter])
    # |> maybe_filter_by_department(filters[:department_filter])
  end

  defp maybe_search(query, term) when term in [nil, ""], do: query
  defp maybe_search(query, search_term) do
    where(query, [f], ilike(f.name, ^"%#{search_term}%"))
  end
end
