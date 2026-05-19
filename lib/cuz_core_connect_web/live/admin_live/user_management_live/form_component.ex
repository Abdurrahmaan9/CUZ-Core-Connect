defmodule CuzCoreConnectWeb.UserFormComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 shadow-lg rounded-box">
      <div class="px-4 py-5 sm:p-6">
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-base-content">
            {if @user.id, do: "Edit User", else: "Create New User"}
          </h3>
          <p class="mt-1 text-sm text-base-content/70">
            {if @user.id, do: "Update user information and permissions", else: "Fill in the form below to create a new user account"}
          </p>
        </div>

        <.form
          :let={f}
          for={@changeset || to_form(%CuzCoreConnect.Accounts.User{})}
          id="user-form"
          phx-submit={if @user.id, do: "update_user", else: "create_user"}
          phx-target={@myself}
          class="space-y-6"
        >
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <.input
                field={f[:email]}
                type="email"
                label="Email Address"
                placeholder="user@cuz.coreconnect.edu"
                class="input input-bordered w-full"
                required
              />
            </div>

            <div>
              <.input
                field={f[:user_role]}
                type="select"
                label="User Role"
                options={[
                  {"Admin", "admin"},
                  {"Academics", "academics"},
                  {"Finance", "finance"},
                  {"HOD", "hod"},
                  {"Student", "student"}
                ]}
                class="select select-bordered w-full"
                required
              />
            </div>
          </div>

          <%= if @user && !@user.id do %>
            <div class="alert alert-info">
              <div class="flex">
                <div class="flex-shrink-0">
                  <.icon name="hero-information-circle" class="h-5 w-5" />
                </div>
                <div class="ml-3">
                  <h3 class="text-sm font-medium">Password Auto-Generation</h3>
                  <div class="mt-2 text-sm">
                    <p>A secure password will be automatically generated for this user and displayed in the terminal after creation.</p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <div class="form-control">
            <label class="label cursor-pointer">
              <input
                type="checkbox"
                name="user[is_active]"
                checked={@user.is_active}
                class="checkbox checkbox-primary"
              />
              <span class="label-text ml-2">Active User</span>
            </label>
          </div>

          <div class="flex justify-end space-x-3">
            <.link href={~p"/admin/users"} class="btn btn-ghost">Cancel</.link>
            <.button type="submit" class="btn btn-primary">
              {if @user.id, do: "Update User", else: "Create User"}
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("create_user", %{"user" => user_params}, socket) do
    send(self(), {:create_user, user_params})
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_user", %{"user" => user_params}, socket) do
    send(self(), {:update_user, user_params, socket.assigns.user.id})
    {:noreply, socket}
  end
end
