defmodule CuzCoreConnect.Notifications do
  @moduledoc """
  In-app notifications shown in the authenticated top-nav bell.

  Created alongside emails for registration progress, pending internal actions,
  announcements, and new admin inbox messages.
  """
  import Ecto.Query, warn: false

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User
  alias CuzCoreConnect.Notifications.Notification
  alias CuzCoreConnect.Registrations.Registration
  alias CuzCoreConnect.Repo

  @internal_roles ~w(admin academics finance hod retention)
  @audience_aliases %{
    "all users" => ["admin", "academics", "finance", "hod", "retention", "student"],
    "all" => ["admin", "academics", "finance", "hod", "retention", "student"],
    "everyone" => ["admin", "academics", "finance", "hod", "retention", "student"],
    "students" => ["student"],
    "student" => ["student"],
    "internal" => @internal_roles,
    "internal users" => @internal_roles,
    "staff" => @internal_roles,
    "admins" => ["admin"],
    "admin" => ["admin"],
    "academics" => ["academics"],
    "finance" => ["finance"],
    "hod" => ["hod"],
    "retention" => ["retention"]
  }

  # ── Queries ──────────────────────────────────────────────────────────────

  def list_notifications(user_id, params \\ %{}) do
    page = parse_positive_int(params[:page] || params["page"], 1)
    page_size = parse_positive_int(params[:per_page] || params["per_page"], 20)

    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at]
    )
    |> apply_filters(params)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def list_brief_notifications(%User{} = user), do: list_brief_notifications(user.id)

  def list_brief_notifications(user_id) when is_integer(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: 8
    )
    |> Repo.all()
  end

  def count_unread(user_id) when is_integer(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and not n.read,
      select: count(n.id)
    )
    |> Repo.one()
  end

  def count_unseen_notifications(user_id), do: count_unread(user_id)

  def get_notification(id), do: Repo.get(Notification, id)

  def get_notification!(id), do: Repo.get!(Notification, id)

  # ── Mutations ────────────────────────────────────────────────────────────

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> broadcast_notification("new_notification")
  end

  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  def mark_as_read(id) when is_binary(id) or is_integer(id) do
    case get_notification(id) do
      nil -> {:error, :not_found}
      notification -> update_notification(notification, %{read: true})
    end
  end

  def mark_all_as_read(user_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(n in Notification, where: n.user_id == ^user_id and not n.read)
    |> Repo.update_all(set: [read: true, updated_at: now])
  end

  @doc """
  Notify a single user. Returns `{:ok, notification}` or `{:error, changeset}`.
  """
  def notify_user(user_or_id, attrs) when is_map(attrs) do
    user_id = user_id(user_or_id)

    attrs
    |> stringify_keys()
    |> Map.put("user_id", user_id)
    |> create_notification()
  end

  @doc """
  Notify many users with the same payload. Returns the list of insert results.
  """
  def notify_users(users, attrs) when is_list(users) and is_map(attrs) do
    Enum.map(users, &notify_user(&1, attrs))
  end

  @doc """
  Notify every active user with one of the given roles.
  """
  def notify_roles(roles, attrs) when is_list(roles) and is_map(attrs) do
    roles
    |> Accounts.list_active_users_by_roles()
    |> notify_users(attrs)
  end

  def notify_roles(role, attrs) when is_binary(role), do: notify_roles([role], attrs)

  # ── Domain helpers (keep emails + in-app bell in sync) ───────────────────

  @doc """
  After a registration is submitted: confirm the student and alert pending queues.
  """
  def notify_registration_submitted(%Registration{} = registration, actor \\ nil) do
    programme = programme_name(registration)
    tracking = registration.tracking_number
    sender = sender_attrs(actor)

    maybe_notify_student(registration, %{
      type: "application",
      status: "info",
      message: "Your registration #{tracking} was submitted for #{programme}.",
      action_url: "/registration/tracking/#{tracking}",
      document_name: tracking,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender))

    notify_roles("finance", %{
      type: "application",
      status: "pending_review",
      message: "Payment verification needed for #{registration.student_names} (#{tracking}).",
      action_url: "/finance/dashboard?tab=pending",
      document_name: tracking,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender))

    notify_roles("academics", %{
      type: "application",
      status: "pending_review",
      message: "Academic review needed for #{registration.student_names} (#{tracking}).",
      action_url: "/academics/dashboard?tab=pending",
      document_name: tracking,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender))

    notify_roles("admin", %{
      type: "application",
      status: "info",
      message: "New registration from #{registration.student_names} (#{tracking}).",
      action_url: "/admin/messages",
      document_name: tracking,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender))

    :ok
  end

  @doc """
  Notify the student of stage approval/rejection, and alert the next role when ready.
  """
  def notify_registration_stage(
        %Registration{} = registration,
        stage,
        status,
        actor \\ nil,
        reason \\ nil
      )
      when stage in ~w(payment academics hod retention) and status in ~w(approved rejected) do
    sender = sender_attrs(actor)
    tracking = registration.tracking_number
    stage_label = stage_label(stage)

    student_attrs =
      case status do
        "approved" ->
          message =
            if stage == "retention" do
              "Registration #{tracking} is fully approved. Your proof of registration is ready."
            else
              "Your registration #{tracking} was approved at the #{stage_label} stage."
            end

          %{
            type: "application",
            status: "approved",
            message: message,
            action_url: tracking_or_proof_url(registration, stage),
            document_name: tracking,
            document_id: to_string(registration.id),
            comments: reason
          }

        "rejected" ->
          %{
            type: "application",
            status: "rejected",
            message:
              "Your registration #{tracking} was rejected at the #{stage_label} stage" <>
                if(reason in [nil, ""], do: ".", else: ": #{reason}"),
            action_url: "/student/dashboard?tab=my_registrations",
            document_name: tracking,
            document_id: to_string(registration.id),
            comments: reason
          }
      end

    maybe_notify_student(registration, Map.merge(student_attrs, sender))

    if status == "approved" do
      notify_next_stage_reviewers(registration, stage, sender)
    end

    :ok
  end

  @doc """
  Notify users matching an announcement audience when it is published.
  """
  def notify_announcement_published(announcement, actor \\ nil) do
    roles = audience_to_roles(announcement.audience)
    sender = sender_attrs(actor)

    notify_roles(roles, %{
      type: "system_message",
      status: "info",
      message: "New announcement: #{announcement.title}",
      action_url: "/",
      document_name: announcement.title,
      document_id: to_string(announcement.id)
    }
    |> Map.merge(sender))

    :ok
  end

  @doc """
  Notify admins about a new external/contact site message.
  """
  def notify_admins_of_message(message, actor \\ nil) do
    sender = sender_attrs(actor)
    from_name = message.name || message.email || "External user"

    notify_roles("admin", %{
      type: "system_message",
      status: "alert",
      message: "New message from #{from_name}: #{message.subject}",
      action_url: "/admin/messages",
      document_name: message.subject,
      document_id: to_string(message.id)
    }
    |> Map.merge(sender))

    :ok
  end

  def audience_to_roles(nil), do: @audience_aliases["all users"]
  def audience_to_roles(""), do: @audience_aliases["all users"]

  def audience_to_roles(audience) when is_binary(audience) do
    audience
    |> String.split(~r/[,&\/]| and /i, trim: true)
    |> Enum.flat_map(fn part ->
      key = part |> String.trim() |> String.downcase()
      Map.get(@audience_aliases, key, [])
    end)
    |> Enum.uniq()
    |> case do
      [] -> @audience_aliases["all users"]
      roles -> roles
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────

  defp notify_next_stage_reviewers(registration, "payment", sender) do
    if registration.accademics_status == "APPROVED" do
      notify_roles("hod", pending_hod_attrs(registration, sender))
    end
  end

  defp notify_next_stage_reviewers(registration, "academics", sender) do
    if registration.payment_status == "APPROVED" do
      notify_roles("hod", pending_hod_attrs(registration, sender))
    end
  end

  defp notify_next_stage_reviewers(registration, "hod", sender) do
    notify_roles("retention", %{
      type: "application",
      status: "pending_review",
      message:
        "Final review needed for #{registration.student_names} (#{registration.tracking_number}).",
      action_url: "/retention/dashboard?tab=pending",
      document_name: registration.tracking_number,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender))
  end

  defp notify_next_stage_reviewers(_registration, _stage, _sender), do: :ok

  defp pending_hod_attrs(registration, sender) do
    %{
      type: "application",
      status: "pending_review",
      message:
        "HOD review needed for #{registration.student_names} (#{registration.tracking_number}).",
      action_url: "/hod/dashboard?tab=pending",
      document_name: registration.tracking_number,
      document_id: to_string(registration.id)
    }
    |> Map.merge(sender)
  end

  defp maybe_notify_student(%Registration{} = registration, attrs) do
    case find_student_user(registration) do
      %User{} = user -> notify_user(user, attrs)
      _ -> :ok
    end
  end

  defp find_student_user(%Registration{} = registration) do
    cond do
      is_binary(registration.student_email) and registration.student_email != "" ->
        Accounts.get_user_by_email(registration.student_email)

      is_binary(registration.student_id) and registration.student_id != "" ->
        Accounts.get_user_by_student_number(registration.student_id)

      true ->
        nil
    end
  end

  defp tracking_or_proof_url(registration, "retention"),
    do: "/registrations/#{registration.id}/certificate"

  defp tracking_or_proof_url(registration, _),
    do: "/registration/tracking/#{registration.tracking_number}"

  defp programme_name(registration) do
    get_in(registration.student_program_details, ["program_name"]) || "your programme"
  end

  defp stage_label("payment"), do: "payment"
  defp stage_label("academics"), do: "academics"
  defp stage_label("hod"), do: "HOD"
  defp stage_label("retention"), do: "final review"
  defp stage_label(other), do: other

  defp sender_attrs(nil), do: %{}

  defp sender_attrs(%User{} = user) do
    %{
      sender_id: user.id,
      sender_name: display_name(user)
    }
  end

  defp sender_attrs(%{id: id} = user) when is_integer(id) do
    %{
      sender_id: id,
      sender_name: display_name(user)
    }
  end

  defp sender_attrs(_), do: %{}

  defp display_name(%{first_name: first, last_name: last})
       when is_binary(first) and first != "" do
    [first, last] |> Enum.reject(&(is_nil(&1) or &1 == "")) |> Enum.join(" ")
  end

  defp display_name(%{username: username}) when is_binary(username) and username != "",
    do: username

  defp display_name(%{email: email}) when is_binary(email), do: email
  defp display_name(_), do: "System"

  defp user_id(%User{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id

  defp stringify_keys(attrs) do
    Map.new(attrs, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp apply_filters(query, %{"status" => status}) when status not in [nil, "", "all"],
    do: from(n in query, where: n.status == ^status)

  defp apply_filters(query, %{"read" => "read"}), do: from(n in query, where: n.read == true)
  defp apply_filters(query, %{"read" => "unread"}), do: from(n in query, where: n.read == false)

  defp apply_filters(query, %{"type" => type}) when type not in [nil, "", "all"],
    do: from(n in query, where: n.type == ^type)

  defp apply_filters(query, %{status: status}) when status not in [nil, "", "all"],
    do: apply_filters(query, %{"status" => status})

  defp apply_filters(query, %{read: read}) when read in ["read", "unread"],
    do: apply_filters(query, %{"read" => read})

  defp apply_filters(query, %{type: type}) when type not in [nil, "", "all"],
    do: apply_filters(query, %{"type" => type})

  defp apply_filters(query, _), do: query

  defp parse_positive_int(value, _default) when is_integer(value) and value > 0, do: value

  defp parse_positive_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_positive_int(_, default), do: default

  defp broadcast_notification({:ok, notification}, action) do
    CuzCoreConnectWeb.Endpoint.broadcast(
      "notifications:#{notification.user_id}",
      action,
      notification
    )

    {:ok, notification}
  end

  defp broadcast_notification(error, _action), do: error
end
