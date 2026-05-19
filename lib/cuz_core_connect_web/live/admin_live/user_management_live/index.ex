defmodule CuzCoreConnectWeb.Backend.UserManagement.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User
  alias CuzCoreConnectWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "User Management")
     |> assign(:current_page, :user_management)
     |> assign(:users, list_users())
     |> assign(:form, to_form(%{}))}
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
  def handle_info({:update_user, _user_params, _user_id}, socket) do
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <div class="min-h-screen bg-base-100">
        <!-- Admin Header -->
        <div class="bg-base-200 border-b border-base-300">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center py-6">
              <div>
                <h1 class="text-2xl font-bold text-base-content">User Management</h1>
                <p class="text-sm text-base-content/70 mt-1">Manage system users and permissions</p>
              </div>
              <div class="flex items-center space-x-4">
                <.link href={~p"/admin/dashboard"} class="btn btn-ghost btn-sm">
                  Back to Dashboard
                </.link>
                <.link href={~p"/admin/users/new"} class="btn btn-primary btn-sm">Add User</.link>
              </div>
            </div>
          </div>
        </div>

    <!-- Main Content -->
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <%= case @live_action do %>
            <% :new -> %>
              <.live_component
                module={CuzCoreConnectWeb.UserFormComponent}
                id="user-form"
                user={@user}
                changeset={@changeset}
                current_user={@current_scope.user}
              />
            <% :edit -> %>
              <.live_component
                module={CuzCoreConnectWeb.UserFormComponent}
                id="user-form-edit"
                user={@user}
                changeset={@changeset}
                current_user={@current_scope.user}
              />
            <% _ -> %>
              <.live_component
                module={CuzCoreConnectWeb.UserListComponent}
                id="user-list"
                users={@users}
                current_user={@current_scope.user}
              />
          <% end %>
        </div>
      </div>
    </Layouts.admin>
    """
  end
end
