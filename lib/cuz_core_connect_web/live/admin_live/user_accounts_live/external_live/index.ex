defmodule CuzCoreConnectWeb.Admin.UserAccounts.External do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User
  alias CuzCoreConnectWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "External User Management")
     |> assign(:current_page, :external_users)
     |> assign(:show_user_page_access_component, false)
     |> assign(:user, nil)
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
        |> redirect(to: ~p"/admin/user-accounts/external")
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
         |> push_navigate(to: ~p"/admin/user-accounts/external")}

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
     |> push_navigate(to: ~p"/admin/user-accounts/external")}
  end

  @impl true
  def handle_info({CuzCoreConnectWeb.Admin.UserPageAccessComponent, {key, msg}}, socket) do
    socket =
      case key do
        :error ->
          socket
          |> put_flash(:error, msg)

        :success ->
          socket
          |> put_flash(:info, msg)

        _ ->
          socket
          |> put_flash(:info, msg)
      end

    {:noreply,
     socket
      |> assign(:show_user_page_access_component, false)
      |> assign(:user, nil)
    }
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
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

  @impl true
  def handle_event("edit_user_page_access", %{"id" => id}, socket) do
    case Accounts.get_user!(id) do
      %User{} = user ->
        {:noreply,
         socket
         |> assign(:show_user_page_access_component, true)
         |> assign(:user, user)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found")}
    end
  end

  # Helper functions
  defp list_users do
    Accounts.list_all_external_users()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.user flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
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
                <.link href={~p"/admin/user-accounts/external/new"} class="btn btn-primary btn-sm">Add User</.link>
              </div>
            </div>
          </div>
        </div>

    <!-- Main Content -->
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <%= case @live_action do %>
            <% :new -> %>
              <.live_component
                module={__MODULE__.FormComponent}
                id="user-form"
                user={@user}
                changeset={@changeset}
                current_user={@current_scope.user}
              />
            <% :edit -> %>
              <.live_component
                module={__MODULE__.FormComponent}
                id="user-form-edit"
                user={@user}
                changeset={@changeset}
                current_user={@current_scope.user}
              />
            <% _ -> %>
              <div class="bg-base-100 shadow-lg rounded-box">
                <div class="px-4 py-5 sm:p-6">
                  <div class="flex justify-between items-center mb-6">
                    <h3 class="text-lg font-semibold text-base-content">All Users</h3>
                    <div class="flex items-center space-x-2">
                      <input
                        type="text"
                        placeholder="Search users..."
                        class="input input-bordered input-sm w-full max-w-xs"
                      />
                      <button class="btn btn-outline btn-sm">Search</button>
                    </div>
                  </div>

                  <div class="overflow-hidden shadow ring-1 ring-base-300 md:rounded-lg">
                    <table class="table table-zebra w-full">
                      <thead>
                        <tr>
                          <th class="text-left text-xs font-medium text-base-content/70">User</th>
                          <th class="text-left text-xs font-medium text-base-content/70">Role</th>
                          <th class="text-left text-xs font-medium text-base-content/70">Status</th>
                          <th class="text-left text-xs font-medium text-base-content/70">Created</th>
                          <th class="text-left text-xs font-medium text-base-content/70">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for user <- @users do %>
                          <tr>
                            <td>
                              <div class="flex items-center space-x-3">
                                <div class="avatar placeholder">
                                  <div class="bg-neutral text-neutral-content rounded-full w-10 h-10">
                                    <span class="text-sm font-medium">
                                      {String.first(user.email)}
                                    </span>
                                  </div>
                                </div>
                                <div>
                                  <div class="text-sm font-medium text-base-content">{user.email}</div>
                                  <div class="text-sm text-base-content/50">ID: {user.id}</div>
                                </div>
                              </div>
                            </td>
                            <td>
                              <div class={"badge badge-sm " <>
                                case user.user_role do
                                  "admin" -> "badge-primary"
                                  "academics" -> "badge-info"
                                  "finance" -> "badge-success"
                                  "hod" -> "badge-warning"
                                  "student" -> "badge-secondary"
                                  _ -> "badge-neutral"
                                end}>
                                {user.user_role}
                              </div>
                            </td>
                            <td>
                              <div class={"badge badge-sm " <>
                                if(user.is_active, do: "badge-success", else: "badge-error")}>
                                {if(user.is_active, do: "Active", else: "Inactive")}
                              </div>
                            </td>
                            <td class="text-sm text-base-content/70">
                              {format_display_datetime(user.inserted_at)}
                            </td>
                            <td>
                              <div class="flex space-x-2">
                                <.link href={~p"/admin/user-accounts/external/#{user.id}/edit"} class="btn btn-xs btn-primary">Edit</.link>
                                <button
                                  phx-click="edit_user_page_access"
                                  phx-value-id={user.id}
                                  class="btn btn-xs btn-error"
                                >
                                  privileges
                                </button>
                                <button
                                  phx-click="delete_user"
                                  phx-value-id={user.id}
                                  class="btn btn-xs btn-error"
                                  onclick="return confirm('Are you sure you want to delete this user?')"
                                >
                                  Delete
                                </button>
                              </div>
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
          <% end %>
        </div>
      </div>

      <.live_component
        :if={@show_user_page_access_component && not is_nil(@user)}
        module={CuzCoreConnectWeb.Admin.UserPageAccessComponent}
        id={"page-access-#{@user.id}"}
        user={@user}
      />
    </Layouts.user>
    """
  end
end
