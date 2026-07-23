defmodule CuzCoreConnect.Communications do
  @moduledoc """
  Announcements and site messages (landing contact + registration notices).
  """
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Communications.Announcement
  alias CuzCoreConnect.Communications.EmailLog
  alias CuzCoreConnect.Communications.SiteMessage
  alias CuzCoreConnect.Registrations.Registration

  # ── Announcements ────────────────────────────────────────────────────────

  def list_announcements do
    from(a in Announcement, order_by: [desc: a.inserted_at])
    |> Repo.all()
  end

  def list_announcements_by_status(status) when status in ~w(draft published scheduled) do
    from(a in Announcement, where: a.status == ^status, order_by: [desc: a.inserted_at])
    |> Repo.all()
  end

  def list_published_announcements(limit \\ 20) do
    now = DateTime.utc_now()

    from(a in Announcement,
      where:
        a.status == "published" or
          (a.status == "scheduled" and not is_nil(a.published_at) and a.published_at <= ^now),
      order_by: [desc: a.published_at, desc: a.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_announcement!(id), do: Repo.get!(Announcement, id)

  def create_announcement(attrs \\ %{}) do
    %Announcement{}
    |> Announcement.changeset(attrs)
    |> Repo.insert()
  end

  def update_announcement(%Announcement{} = announcement, attrs) do
    announcement
    |> Announcement.changeset(attrs)
    |> Repo.update()
  end

  def delete_announcement(%Announcement{} = announcement) do
    Repo.delete(announcement)
  end

  def change_announcement(%Announcement{} = announcement, attrs \\ %{}) do
    Announcement.changeset(announcement, attrs)
  end

  def announcement_stats do
    rows =
      from(a in Announcement, group_by: a.status, select: {a.status, count(a.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: Map.values(rows) |> Enum.sum(),
      published: Map.get(rows, "published", 0),
      drafts: Map.get(rows, "draft", 0),
      scheduled: Map.get(rows, "scheduled", 0)
    }
  end

  # ── Site messages ────────────────────────────────────────────────────────

  def list_messages do
    from(m in SiteMessage, order_by: [desc: m.inserted_at])
    |> Repo.all()
  end

  def list_messages_by_status(status) when status in ~w(unread read archived) do
    from(m in SiteMessage, where: m.status == ^status, order_by: [desc: m.inserted_at])
    |> Repo.all()
  end

  def list_landing_messages(limit \\ 12) do
    from(m in SiteMessage,
      where: m.show_on_landing == true and m.status != "archived",
      order_by: [desc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_message!(id), do: Repo.get!(SiteMessage, id)

  def create_message(attrs \\ %{}) do
    %SiteMessage{}
    |> SiteMessage.changeset(attrs)
    |> Repo.insert()
  end

  def create_contact_message(attrs) do
    %SiteMessage{}
    |> SiteMessage.contact_changeset(attrs)
    |> Repo.insert()
  end

  def change_contact_message(attrs \\ %{}) do
    SiteMessage.contact_changeset(%SiteMessage{}, attrs)
  end

  @doc """
  Creates a public landing-page notice when a student submits a registration.
  """
  def create_registration_message(%Registration{} = registration) do
    programme =
      get_in(registration.student_program_details, ["program_name"]) || "a programme"

    create_message(%{
      name: registration.student_names || "Student",
      email: registration.student_email,
      subject: "New registration submitted",
      body:
        "#{registration.student_names} submitted a registration for #{programme} (#{registration.tracking_number}).",
      source: "registration",
      status: "unread",
      priority: "normal",
      show_on_landing: true,
      registration_id: registration.id
    })
  end

  def update_message(%SiteMessage{} = message, attrs) do
    message
    |> SiteMessage.changeset(attrs)
    |> Repo.update()
  end

  def mark_message_read(%SiteMessage{} = message) do
    update_message(message, %{status: "read"})
  end

  def archive_message(%SiteMessage{} = message) do
    update_message(message, %{status: "archived", show_on_landing: false})
  end

  def delete_message(%SiteMessage{} = message) do
    Repo.delete(message)
  end

  def message_stats do
    rows =
      from(m in SiteMessage, group_by: m.status, select: {m.status, count(m.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: Map.values(rows) |> Enum.sum(),
      unread: Map.get(rows, "unread", 0),
      read: Map.get(rows, "read", 0),
      archived: Map.get(rows, "archived", 0)
    }
  end

  # ── Email logs ───────────────────────────────────────────────────────────

  def list_email_logs(limit \\ 100) do
    from(l in EmailLog, order_by: [desc: l.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  def list_email_logs_by_status(status, limit \\ 100)
      when status in ~w(sent failed) do
    from(l in EmailLog,
      where: l.status == ^status,
      order_by: [desc: l.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_email_log!(id), do: Repo.get!(EmailLog, id)

  def create_email_log(attrs \\ %{}) do
    %EmailLog{}
    |> EmailLog.changeset(attrs)
    |> Repo.insert()
  end

  def delete_email_log(%EmailLog{} = log) do
    Repo.delete(log)
  end

  def email_log_stats do
    rows =
      from(l in EmailLog, group_by: l.status, select: {l.status, count(l.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: Map.values(rows) |> Enum.sum(),
      sent: Map.get(rows, "sent", 0),
      failed: Map.get(rows, "failed", 0)
    }
  end
end
