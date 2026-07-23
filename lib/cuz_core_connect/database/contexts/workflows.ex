defmodule CuzCoreConnect.Workflows do
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnectWeb.Datatable.Pagination
  alias CuzCoreConnect.Workflows.RegistrationWorkflow

  def get_active_registration_flow do
    Repo.one(
      from w in RegistrationWorkflow,
        where: w.is_active == true and is_nil(w.deleted_at),
        order_by: [desc: w.updated_at],
        limit: 1
    )
  end

  @doc """
  Lists non-deleted registration workflows for dashboard status display.
  Active workflows are listed first.
  """
  def list_registration_workflows do
    from(w in RegistrationWorkflow,
      where: is_nil(w.deleted_at),
      order_by: [desc: w.is_active, asc: w.name]
    )
    |> Repo.all()
  end

  def count_active_registration_workflows do
    from(w in RegistrationWorkflow,
      where: w.is_active == true and is_nil(w.deleted_at),
      select: count(w.id)
    )
    |> Repo.one()
  end

  @doc """
  Activates the given workflow and deactivates every other non-deleted workflow.
  Only one registration workflow can be active at a time. New registrations
  pick up the active workflow via `Registration.put_active_workflow/1`.
  """
  def set_active_registration_flow(id) when is_integer(id) do
    Repo.transaction(fn ->
      workflow =
        RegistrationWorkflow
        |> where([w], w.id == ^id and is_nil(w.deleted_at))
        |> Repo.one()

      if is_nil(workflow) do
        Repo.rollback(:not_found)
      else
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        # Turn off every other active workflow first.
        Repo.update_all(
          from(w in RegistrationWorkflow,
            where: w.id != ^id and w.is_active == true and is_nil(w.deleted_at)
          ),
          set: [is_active: false, updated_at: now]
        )

        case workflow
             |> RegistrationWorkflow.changeset(%{is_active: true})
             |> Repo.update() do
          {:ok, updated} -> updated
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    end)
  end

  def set_active_registration_flow(id) when is_binary(id) do
    set_active_registration_flow(String.to_integer(id))
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
    attrs = for {k, v} <- attrs, into: %{}, do: {to_string(k), v}
    want_active? = truthy?(attrs["is_active"])

    # Never insert as active directly — activate in a second step so we can
    # guarantee only one active workflow exists.
    insert_attrs = Map.put(attrs, "is_active", false)

    Repo.transaction(fn ->
      case %RegistrationWorkflow{}
           |> RegistrationWorkflow.changeset(insert_attrs)
           |> Repo.insert() do
        {:ok, workflow} ->
          if want_active? do
            case set_active_registration_flow(workflow.id) do
              {:ok, active} -> active
              {:error, reason} -> Repo.rollback(reason)
            end
          else
            workflow
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp truthy?(true), do: true
  defp truthy?("true"), do: true
  defp truthy?("1"), do: true
  defp truthy?(1), do: true
  defp truthy?(_), do: false

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
