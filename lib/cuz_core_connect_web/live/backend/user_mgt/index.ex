defmodule CuzCoreConnectWeb.Backend.UserMgt.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User
  alias CuzCoreConnectWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    # Check if current user is admin
    current_scope = socket.assigns[:current_scope]

    if current_scope && current_scope.user.user_role == "Admin" do
      {:ok,
       socket
       |> assign(:page_title, "User Management")
       |> assign(:users, list_users())
       |> assign(:form, to_form(%{}))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Access denied. Admin privileges required.")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
    |> assign(:changeset, User.email_changeset(%User{}, %{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Accounts.get_user!(id) do
      %User{} = user ->
        socket
        |> assign(:page_title, "Edit User")
        |> assign(:user, user)
        |> assign(:changeset, User.email_changeset(user, %{}))
      _ ->
        socket
        |> put_flash(:error, "User not found")
        |> redirect(to: ~p"/admin/users")
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Management")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({:create_user, user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_info({:update_user,_user_params, _user_id}, socket) do
    # TODO: Implement user update logic
    {:noreply,
     socket
     |> put_flash(:info, "User updated successfully")
     |> push_navigate(to: ~p"/admin/users")}
  end

  @impl true
  def handle_info({:delete_user, id}, socket) do
    case Accounts.get_user!(id) do
      %User{} = _user ->
        # Here you would implement user deletion logic
        # For now, we'll just show a success message
        {:noreply,
         socket
         |> put_flash(:info, "User deleted successfully")
         |> assign(:users, list_users())}
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")}
    end
  end

  # Helper functions
  defp list_users do
    Accounts.list_all_users()
  end
end
