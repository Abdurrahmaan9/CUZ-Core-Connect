defmodule CuzCoreConnect.Workflows do
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnectWeb.Pagination
  alias CuzCoreConnect.Workflows.RegistrationWorkflow

  def get_active_registration_flow do
    Repo.one(
      from w in RegistrationWorkflow,
        where: w.is_active == true and is_nil(w.deleted_at),
        limit: 1
    )
  end

  def set_active_registration_flow(id) do
    Repo.transaction(fn ->
      # Deactivate all others first
      Repo.update_all(
        from(w in RegistrationWorkflow, where: w.id != ^id),
        set: [is_active: false]
      )

      workflow = Repo.get!(RegistrationWorkflow, id)

      workflow
      |> RegistrationWorkflow.changeset(%{is_active: true})
      |> Repo.update()
      |> case do
        {:ok, updated} -> updated
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Count in-progress registrations still using a given workflow_id
  def count_incomplete_registrations_by_workflow(workflow_id) do
    Repo.one(
      from r in CuzCoreConnect.Registrations.Registration,
        where: r.workflow_id == ^workflow_id and r.registration_status == "PENDING",
        select: count(r.id)
    )
  end

  def list_peginated_registration_flows(filters \\ %{}) do
    page_params = %{
      page: Pagination.param_value(filters, :page, 1),
      page_size: Pagination.param_value(filters, :page_size, 10)
    }

    query =
      RegistrationWorkflow
      |> where([f], is_nil(f.deleted_at))
      |> apply_filters(filters)
      |> order_by(desc: :name)

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

  defp apply_filters(query, filters) do
    query
    |> maybe_filter_by_search(filters[:search_filter])
  end

  defp maybe_filter_by_search(query, term) when term in [nil, ""], do: query
  defp maybe_filter_by_search(query, search_term) do
    where(query, [f], ilike(f.name, ^"%#{search_term}%"))
  end
end
