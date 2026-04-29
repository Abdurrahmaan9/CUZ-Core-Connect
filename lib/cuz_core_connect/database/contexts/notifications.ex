defmodule CuzCoreConnect.Notifications do
  import Ecto.Query, warn: false
  alias CuzCoreConnect.Repo
  alias CuzCoreConnect.Notifications.Notification
  # alias CuzCoreConnect.Communications.EmailLog
  alias Scrivener

  def list_notifications(user_id, params \\ %{}) do
    base_query = from(n in Notification, where: n.user_id == ^user_id)

    query =
      base_query
      |> apply_filters(params)
      |> order_by(desc: :inserted_at)

    query
    |> Repo.paginate(
      page: params[:page] || 1,
      page_size: params[:per_page] || 4
    )
  end

  def get_memo_notification_by_document_id(id, user_id, document_name \\ false) do
    Notification
    |> where([n], n.document_id == ^id)
    |> where([n], n.document_name == ^document_name)
    |> where([n], n.user_id == ^user_id)
    |> where([n], n.read == false)
    |> Repo.all()
  end

  def list_brief_notifications(user) do
    Notification
    |> where([n], n.user_id == ^user.id)
    # |> where([n], n.read == false)
    |> order_by([n], desc: n.inserted_at)
    |> limit(5)
    |> Repo.all()
  end

  def count_unseen_notifications(user_id) do
    from(n in Notification, where: n.user_id == ^user_id and not n.read)
    |> Repo.aggregate(:count, :id)
  end

  def get_notification(id) do
    Notification
    |> Repo.get(id)
  end

  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  defp apply_filters(query, %{"status" => status}) when status != "all",
    do: from(n in query, where: n.status == ^status)

  defp apply_filters(query, %{"read" => "read"}), do: from(n in query, where: n.read == true)
  defp apply_filters(query, %{"read" => "unread"}), do: from(n in query, where: n.read == false)

  defp apply_filters(query, %{"type" => type}) when type != "all",
    do: from(n in query, where: n.type == ^type)

  defp apply_filters(query, _params), do: query

  def count_unread(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and not n.read,
      select: count(n.id)
    )
    |> Repo.one()
  end

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> broadcast_notification("new_notification")
  end

  def mark_as_read(id) do
    Notification
    |> Repo.get(id)
    |> Notification.changeset(%{read: true})
    |> Repo.update()

    # |> broadcast_notification("notification_read")
  end

  def mark_all_as_read(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and not n.read
    )
    |> Repo.update_all(set: [read: true, updated_at: DateTime.utc_now()])
  end

  defp broadcast_notification({:ok, notification}, action) do
    CuzCoreConnectWeb.Endpoint.broadcast(
      "notifications:#{notification.user_id}",
      action,
      notification
    )

    {:ok, notification}
  end

  defp broadcast_notification(error, _action), do: error

  def create_approval_notification(action, memo, user, comments) do
    message =
      "#{user.firstname} #{user.lastname} has #{action}ed your memo."

    status = if action == "approve", do: "approved", else: "rejected"

    create_notification(%{
      user_id: memo.creator_id,
      type: "document",
      message: message,
      status: status,
      sender: user.id,
      action_url: "/memos",
      document_name: memo.subject,
      document_id: memo.id,
      comments: comments,
      sender_id: user.id,
      sender_name: "#{user.firstname} #{user.lastname}"
    })
  end

  def build_and_create_notification(user_id, sender, message, document_title, document_id, url) do
    create_notification(%{
      user_id: user_id,
      sender_id: sender.id,
      sender_name: sender.username,
      document_name: document_title,
      document_id: "#{document_id}",
      message: message,
      action_url: url
    })
  end

  # @doc """
  # email_log = %CuzCoreConnect.Communications.EmailLog{
  #   to: "
  # """

  # def log_email(to, subject, status, notif_type, action_url, error_message \\ nil) do
  #   %CuzCoreConnect.Communications.EmailLog{}
  #   |> CuzCoreConnect.Communications.EmailLog.changeset(%{
  #     to: to,
  #     subject: subject,
  #     status: status,
  #     notif_type: notif_type,
  #     action_url: action_url,
  #     error_message: error_message
  #   })
  #   |> Repo.insert()
  # end
end
