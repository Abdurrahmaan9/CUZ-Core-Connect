defmodule CuzCoreConnect.Communications.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published scheduled)

  schema "tbl_announcements" do
    field :title, :string
    field :body, :string
    field :audience, :string, default: "All Users"
    field :author, :string, default: "Admin"
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :views, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:title, :body, :audience, :author, :status, :published_at, :views])
    |> validate_required([:title, :body, :status])
    |> validate_inclusion(:status, @statuses)
    |> maybe_set_published_at()
  end

  defp maybe_set_published_at(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    cond do
      status == "published" and is_nil(published_at) ->
        put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))

      status == "draft" ->
        put_change(changeset, :published_at, nil)

      true ->
        changeset
    end
  end
end
