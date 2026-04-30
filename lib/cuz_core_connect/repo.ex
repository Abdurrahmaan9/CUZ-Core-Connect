defmodule CuzCoreConnect.Repo do
  use Ecto.Repo,
    otp_app: :cuz_core_connect,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  def cast_list_to_repo(changesets) when is_list(changesets) do
    changesets
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {changeset, idx}, multi ->
      Ecto.Multi.insert(multi, :"insert_#{idx}", changeset)
    end)
    |> transaction()
  end
end
