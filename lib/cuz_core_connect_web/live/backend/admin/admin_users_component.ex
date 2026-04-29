defmodule CuzCoreConnectWeb.Admin.AdminUsersComponent do
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
          <.link href={~p"/admin/users/new"} class="btn btn-primary btn-sm">Add User</.link>
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
                        "Admin" -> "badge-primary"
                        "Academics" -> "badge-info"
                        "Finance" -> "badge-success"
                        "HOD" -> "badge-warning"
                        "Student" -> "badge-secondary"
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
                    <div class="flex space-x-2">
                      <.link href={~p"/admin/users/#{user.id}/edit"} class="btn btn-xs btn-primary">Edit</.link>
                      <.link href={~p"/admin/users"} class="btn btn-xs btn-secondary">View All</.link>
                    </div>
                  </td>
                </tr>
              <% end %>
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
