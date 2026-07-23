defmodule CuzCoreConnect.Communications.SiteMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @sources ~w(contact registration system)
  @statuses ~w(unread read archived)
  @priorities ~w(low normal high)

  schema "tbl_site_messages" do
    field :name, :string
    field :email, :string
    field :subject, :string
    field :body, :string
    field :source, :string, default: "contact"
    field :status, :string, default: "unread"
    field :priority, :string, default: "normal"
    field :show_on_landing, :boolean, default: false

    belongs_to :registration, CuzCoreConnect.Registrations.Registration

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :name,
      :email,
      :subject,
      :body,
      :source,
      :status,
      :priority,
      :show_on_landing,
      :registration_id
    ])
    |> validate_required([:name, :subject, :body, :source, :status])
    |> validate_inclusion(:source, @sources)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:priority, @priorities)
  end

  def contact_changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :email, :subject, :body])
    |> validate_required([:name, :email, :subject, :body])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> put_change(:source, "contact")
    |> put_change(:status, "unread")
    |> put_change(:priority, "normal")
    |> put_change(:show_on_landing, false)
  end
end
