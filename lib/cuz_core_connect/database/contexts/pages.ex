defmodule CuzCoreConnect.Pages do
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Pages.{Page, UserPageAccess}
  import Ecto.Query, warn: false

  def all_pages() do
    Repo.all(from p in Page, where: p.is_deleted == false)
  end

  def all_pages_cached() do
    case Cachex.get(:cuz_core_connect_cache, "pages") do
      {:ok, nil} ->
        pages = all_pages()
        Cachex.put(:cuz_core_connect_cache, "pages", pages, ttl: :timer.minutes(10))
        pages

      {:ok, pages} ->
        pages

      _ ->
        all_pages()
    end
  end

  def bust_pages_cache() do
    Cachex.del(:cuz_core_connect_cache, "pages")
  end

  @doc """
  Resolves the page key from a request path by matching against
  stored page paths, supporting dynamic segments like :id.

  Examples:
    resolve_page_key("/merchant/transactions/123") => "transactions_reports"
    resolve_page_key("/merchant/webhooks/new")     => "webhooks"
    resolve_page_key("/merchant/unknown")          => nil
  """
  def resolve_page_key(path, pages \\ nil) do
    pages = pages || all_pages_cached()

    Enum.find_value(pages, fn page ->
      if path_matches_any?(path, page.paths), do: page.name
    end)
  end

  @doc """
  Checks if a user's page_access map grants access to the given path.
  Optionally checks for a specific action (default: "view").

  Examples:
    has_page_access?(%{"dashboard" => ["view"]}, "/merchant/dashboard")           => true
    has_page_access?(%{"dashboard" => ["view"]}, "/merchant/dashboard", "delete") => false
    has_page_access?(%{}, "/merchant/dashboard")                                  => false
  """
  def has_page_access?(page_access, path, action \\ nil) do
    # IO.inspect({page_access, path}, label: "===y")
    case resolve_page_key(path) do
      nil ->
        true

      page_key ->
        allowed = Map.get(page_access, page_key, [])

        case action do
          # just needs any access
          nil -> allowed != []
          act -> Enum.member?(allowed, act)
        end
    end
  end

  @doc """
  Builds the default page_access map for a merchant user
  by pulling all non-admin pages from the DB.
  """
  def default_merchant_page_access(pages \\ nil) do
    pages = pages || all_pages_cached()

    pages
    |> Enum.reject(& &1.is_admin)
    |> Map.new(fn page ->
      {page.name, page.actions}
    end)
  end

  @doc """
  Builds the default page_access map for an admin user
  by pulling all admin pages from the DB.
  """
  def default_admin_page_access(pages \\ nil) do
    pages = pages || all_pages_cached()

    pages
    |> Enum.filter(& &1.is_admin)
    |> Map.new(fn page ->
      {page.name, page.actions}
    end)
  end

  @doc """
  Returns all available page keys for a given scope (:merchant | :admin)
  Useful for building role permission UIs.
  """
  def available_page_keys(scope, pages \\ nil)

  def available_page_keys(:merchant, pages) do
    pages = pages || all_pages_cached()
    pages |> Enum.reject(& &1.is_admin) |> Enum.map(& &1.name)
  end

  def available_page_keys(:admin, pages) do
    pages = pages || all_pages_cached()
    pages |> Enum.filter(& &1.is_admin) |> Enum.map(& &1.name)
  end

  # Matches a real path like "/merchant/transactions/123"
  # against a pattern like "/merchant/transactions/:id"
  defp path_matches_any?(path, patterns) do
    Enum.any?(patterns, &path_matches?(path, &1))
  end

  defp path_matches?(path, pattern) do
    path_parts = String.split(path, "/", trim: true)
    pattern_parts = String.split(pattern, "/", trim: true)

    length(path_parts) == length(pattern_parts) &&
      Enum.zip(path_parts, pattern_parts)
      |> Enum.all?(fn
        {_, ":" <> _} -> true
        {a, b} -> a == b
      end)
  end

  def list_merchant_pages do
    Page
    |> where([p], p.is_deleted == false)
    |> where([p], p.is_admin == false)
    |> Repo.all()
    |> Enum.map(& &1.name)
  end

  def list_admin_pages do
    Page
    |> where([p], p.is_deleted == false)
    |> where([p], p.is_admin == true)
    |> Repo.all()
    |> Enum.map(& &1.name)
  end

  def list_pages do
    Page
    |> order_by([p], asc: p.name)
    # |> preload(:department)
    |> Repo.all()
  end

  def list_pages_for_role(role) do
    Repo.all(from p in Page, where: p.role == ^role, order_by: p.name)
  end

  # ── Assign default role pages to a newly registered user ─────────────────

  def assign_default_pages_for_user(user) do
    role = user.user_role
    pages = list_pages_for_role(role)

    Repo.transaction(fn ->
      Enum.each(pages, fn page ->
        %UserPageAccess{}
        |> UserPageAccess.changeset(%{
          user_id: user.id,
          page_id: page.id,
          actions: page.actions
        })
        |> Repo.insert!(
          on_conflict: :nothing,
          conflict_target: [:user_id, :page_id]
        )
      end)
    end)
  end

  # ── Fetch a user's page access (preloaded with page data) ─────────────────

  def get_user_page_access(user_id) do
    Repo.all(
      from upa in UserPageAccess,
        join: p in assoc(upa, :page),
        where: upa.user_id == ^user_id,
        preload: [page: p]
    )
  end

  # ── Build a map of %{page_name => [actions]} for fast lookup ──────────────

  def build_access_map(user_id) do
    user_id
    |> get_user_page_access()
    |> Map.new(fn upa -> {upa.page.name, upa.actions} end)
  end

  # ── Admin: override a user's actions for a specific page ─────────────────

  def update_user_page_actions(user_id, page_id, actions) do
    case Repo.get_by(UserPageAccess, user_id: user_id, page_id: page_id) do
      nil ->
        %UserPageAccess{}
        |> UserPageAccess.changeset(%{user_id: user_id, page_id: page_id, actions: actions})
        |> Repo.insert()

      existing ->
        existing
        |> UserPageAccess.changeset(%{actions: actions})
        |> Repo.update()
    end
  end

  # ── Admin: grant/revoke a page entirely ──────────────────────────────────

  def grant_page_access(user_id, page_id, actions \\ ["view"]) do
    %UserPageAccess{}
    |> UserPageAccess.changeset(%{user_id: user_id, page_id: page_id, actions: actions})
    |> Repo.insert(on_conflict: {:replace, [:actions]}, conflict_target: [:user_id, :page_id])
  end

  def revoke_page_access(user_id, page_id) do
    Repo.delete_all(
      from upa in UserPageAccess,
        where: upa.user_id == ^user_id and upa.page_id == ^page_id
    )
  end

  # ── Helpers for LiveView checks ───────────────────────────────────────────

  def can_access_page?(access_map, page_name) do
    Map.has_key?(access_map, page_name)
  end

  def can_perform?(access_map, page_name, action) do
    access_map
    |> Map.get(page_name, [])
    |> Enum.member?(to_string(action))
  end

  @doc """
  Gets a single page.

  Raises `Ecto.NoResultsError` if the Page does not exist.

  ## Examples

      iex> get_page!(123)
      %Page{}

      iex> get_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_page!(id) do
    Page
    # |> preload(:department)
    |> Repo.get!(id)
  end

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page.

  ## Examples

      iex> update_page(page, %{field: new_value})
      {:ok, %Page{}}

      iex> update_page(page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a page.

  ## Examples

      iex> delete_page(page)
      {:ok, %Page{}}

      iex> delete_page(page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.

  ## Examples

      iex> change_page(page)
      %Ecto.Changeset{data: %Page{}}

  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end
end
