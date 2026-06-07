defmodule CuzCoreConnect.Pages.UserPageAccess do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tbl_user_page_access" do
    belongs_to :user, CuzCoreConnect.Accounts.User
    belongs_to :page, CuzCoreConnect.Pages.Page
    field :actions, {:array, :string}, default: ["view"]
    timestamps(type: :utc_datetime)
  end

  def changeset(access, attrs) do
    access
    |> cast(attrs, [:user_id, :page_id, :actions])
    |> validate_required([:user_id, :page_id])
    |> unique_constraint([:user_id, :page_id])
  end
end
