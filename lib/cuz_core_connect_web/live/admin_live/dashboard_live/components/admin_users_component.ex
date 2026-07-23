defmodule CuzCoreConnectWeb.AdminLiveAdminUsersComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    users = CuzCoreConnect.Accounts.list_all_users()
    {:ok, assign(socket, Map.merge(assigns, %{users: users}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 shadow-lg rounded-box">
      <div class="px-4 py-5 sm:p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-lg font-semibold text-base-content">User Management</h3>
          <.link href="/admin/users/new" class="btn btn-primary btn-sm">Add User</.link>
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
              <tr :for={user <- @users}>
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
                  {format_date(user.inserted_at)}
                </td>
                <td>
                  <div class="flex space-x-1 justify-end">
                    <div title="Edit" class="inline-flex">
                      <.link
                        href={"/admin/users/#{user.id}/edit"}
                        class="btn btn-ghost btn-sm btn-square text-warning hover:bg-warning/10"
                        aria-label="Edit"
                      >
                        <.icon name="hero-pencil-square" class="size-5" />
                      </.link>
                    </div>
                    <div title="View all users" class="inline-flex">
                      <.link
                        href="/admin/users"
                        class="btn btn-ghost btn-sm btn-square text-info hover:bg-info/10"
                        aria-label="View all users"
                      >
                        <.icon name="hero-users" class="size-5" />
                      </.link>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
