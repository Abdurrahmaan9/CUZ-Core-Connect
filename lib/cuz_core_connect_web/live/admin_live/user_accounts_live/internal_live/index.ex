defmodule CuzCoreConnectWeb.Admin.UserAccounts.Internal do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User

  @internal_roles [
    {"Admin", "admin"},
    {"Academics", "academics"},
    {"Finance", "finance"},
    {"HOD", "hod"},
    {"Retention", "retention"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Internal Users",
       current_page: :internal_users,
       show_form: false,
       form: nil,
       show_page_access: false,
       access_user: nil,
       query: ""
     )
     |> load_users()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      %User{is_active: true, status: "ACTIVE", user_role: "academics"}
      |> User.admin_changeset(%{})
      |> to_form()

    socket
    |> assign(page_title: "New Internal User", show_form: true, form: form, access_user: nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)

    if user.user_role == "student" do
      socket
      |> put_flash(:error, "That account is an external (student) user.")
      |> push_navigate(to: ~p"/admin/user-accounts/internal")
    else
      form = user |> User.admin_changeset(%{}) |> to_form()

      socket
      |> assign(page_title: "Edit Internal User", show_form: true, form: form, access_user: nil)
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(
      page_title: "Internal Users",
      show_form: false,
      form: nil,
      access_user: nil,
      show_page_access: false
    )
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> load_users()}
  end

  def handle_event("new", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/user-accounts/internal/new")}
  end

  def handle_event("close", _params, socket) do
    {:noreply,
     socket
     |> assign(show_form: false, form: nil, show_page_access: false, access_user: nil)
     |> push_patch(to: ~p"/admin/user-accounts/internal")}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      socket.assigns.form.data
      |> User.admin_changeset(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    params = normalize_params(params, default_role: "academics")

    result =
      case socket.assigns.form.data.id do
        nil -> Accounts.register_user(params, notify: true)
        _id -> Accounts.update_user(socket.assigns.form.data, params)
      end

    case result do
      {:ok, user} ->
        flash =
          if is_nil(socket.assigns.form.data.id) do
            "User created. Login credentials were emailed to #{user.email}."
          else
            "User updated successfully."
          end

        {:noreply,
         socket
         |> put_flash(:info, flash)
         |> assign(show_form: false, form: nil)
         |> load_users()
         |> push_patch(to: ~p"/admin/user-accounts/internal")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.deactivate_user(user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User deactivated.")
         |> load_users()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to deactivate user.")}
    end
  end

  def handle_event("edit_user_page_access", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    {:noreply,
     socket
     |> assign(show_page_access: true, access_user: user, show_form: false)}
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({CuzCoreConnectWeb.Admin.UserPageAccessComponent, {_key, msg}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, msg)
     |> assign(show_page_access: false, access_user: nil)}
  end

  # Swoosh.Adapters.Test (and Local in some setups) notifies the calling process.
  def handle_info({:email, _email}, socket), do: {:noreply, socket}

  defp load_users(socket) do
    query = String.trim(socket.assigns[:query] || "")
    all_users = Accounts.list_all_internal_users()

    users =
      Enum.filter(all_users, fn user ->
        query == "" or
          String.contains?(String.downcase(user.email || ""), String.downcase(query)) or
          String.contains?(String.downcase(user.username || ""), String.downcase(query))
      end)

    stats = %{
      total: length(all_users),
      active: Enum.count(all_users, & &1.is_active),
      inactive: Enum.count(all_users, &(not &1.is_active))
    }

    socket
    |> assign(:users, users)
    |> assign(:stats, stats)
  end

  defp normalize_params(params, opts) do
    default_role = Keyword.get(opts, :default_role, "academics")

    params =
      params
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put_new("is_active", "false")
      |> Map.put_new("status", "ACTIVE")
      |> Map.put_new("user_role", default_role)

    params =
      case params["is_active"] do
        v when v in [true, "true", "on", "1"] -> Map.put(params, "is_active", true)
        _ -> Map.put(params, "is_active", false)
      end

    username =
      case String.trim(params["username"] || "") do
        "" ->
          params["email"]
          |> to_string()
          |> String.split("@")
          |> List.first()
          |> Kernel.||("user")

        name ->
          name
      end

    Map.put(params, "username", username)
  end

  defp role_badge("admin"), do: "badge-primary"
  defp role_badge("academics"), do: "badge-info"
  defp role_badge("finance"), do: "badge-success"
  defp role_badge("hod"), do: "badge-warning"
  defp role_badge("retention"), do: "badge-secondary"
  defp role_badge(_), do: "badge-neutral"

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :role_options, @internal_roles)

    ~H"""
    <Layouts.user
      flash={@flash}
      current_scope={@current_scope}
      page_title={@page_title}
      current_page={@current_page}
    >
      <div class="space-y-6">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold text-base-content">Internal Users</h1>
            <p class="text-sm text-base-content/60">
              Staff accounts (admin, academics, finance, HOD, retention).
            </p>
          </div>
          <button type="button" phx-click="new" class="btn btn-primary btn-sm gap-2">
            <.icon name="hero-plus" class="size-4" /> New user
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Total</p>
            <p class="text-xl font-semibold">{@stats.total}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Active</p>
            <p class="text-xl font-semibold text-success">{@stats.active}</p>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm">
            <p class="text-sm text-base-content/60">Inactive</p>
            <p class="text-xl font-semibold text-error">{@stats.inactive}</p>
          </div>
        </div>

        <div class="rounded-box border border-base-300 bg-base-100 shadow-sm">
          <div class="flex flex-col gap-3 border-b border-base-300 p-4 sm:flex-row sm:items-center sm:justify-between">
            <h2 class="font-semibold text-base-content">All internal users</h2>
            <form phx-change="search" id="internal-user-search" class="w-full sm:w-72">
              <input
                type="search"
                name="query"
                value={@query}
                placeholder="Search email or username…"
                class="input input-bordered input-sm w-full"
              />
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr class="text-xs text-base-content/60">
                  <th>User</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th class="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={user <- @users} id={"internal-user-#{user.id}"} class="hover">
                  <td>
                    <div class="flex items-center gap-3">
                      <div class="flex size-10 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary">
                        {user.email |> String.first() |> String.upcase()}
                      </div>
                      <div>
                        <p class="font-medium text-base-content">{user.email}</p>
                        <p class="text-xs text-base-content/50">@{user.username}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span class={["badge badge-sm capitalize", role_badge(user.user_role)]}>
                      {user.user_role}
                    </span>
                  </td>
                  <td>
                    <span class={[
                      "badge badge-sm",
                      if(user.is_active, do: "badge-success", else: "badge-error")
                    ]}>
                      {if(user.is_active, do: "Active", else: "Inactive")}
                    </span>
                  </td>
                  <td class="text-sm text-base-content/70">
                    {format_display_datetime(user.inserted_at)}
                  </td>
                  <td>
                    <div class="flex justify-end gap-1">
                      <div title="Edit" class="inline-flex">
                        <.link
                          patch={~p"/admin/user-accounts/internal/#{user.id}/edit"}
                          class="btn btn-ghost btn-sm btn-square text-warning hover:bg-warning/10"
                          aria-label="Edit"
                        >
                          <.icon name="hero-pencil-square" class="size-5" />
                        </.link>
                      </div>
                      <div title="Privileges" class="inline-flex">
                        <button
                          type="button"
                          phx-click="edit_user_page_access"
                          phx-value-id={user.id}
                          class="btn btn-ghost btn-sm btn-square text-primary hover:bg-primary/10"
                          aria-label="Privileges"
                        >
                          <.icon name="hero-key" class="size-5" />
                        </button>
                      </div>
                      <div title="Deactivate" class="inline-flex">
                        <button
                          type="button"
                          phx-click="delete_user"
                          phx-value-id={user.id}
                          data-confirm="Deactivate this user?"
                          class="btn btn-ghost btn-sm btn-square text-error hover:bg-error/10"
                          aria-label="Deactivate"
                        >
                          <.icon name="hero-trash" class="size-5" />
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
                <tr :if={@users == []}>
                  <td colspan="5" class="py-10 text-center text-base-content/50">
                    No internal users found.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div
        :if={@show_form && @form}
        id="internal-user-form-modal"
        class="fixed inset-0 z-[100] grid place-items-center bg-black/50 p-4"
        phx-window-keydown="close"
        phx-key="Escape"
      >
        <div class="w-full max-w-lg rounded-2xl bg-base-100 p-6 shadow-2xl" phx-click="noop">
          <h3 class="mb-1 text-lg font-bold">
            {if @form.data.id, do: "Edit internal user", else: "Create internal user"}
          </h3>
          <p class="mb-4 text-sm text-base-content/60">
            {if @form.data.id,
              do: "Update account details and role.",
              else: "A secure password is generated automatically."}
          </p>

          <.form
            for={@form}
            id="internal-user-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-4"
          >
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:username]} type="text" label="Username" required />
            <.input
              field={@form[:user_role]}
              type="select"
              label="Role"
              options={@role_options}
              required
            />
            <.input field={@form[:is_active]} type="checkbox" label="Active user" />

            <div
              :if={is_nil(@form.data.id)}
              class="rounded-box border border-info/30 bg-info/10 p-3 text-sm text-base-content/80"
            >
              <.icon name="hero-information-circle" class="mr-1 inline size-4 text-info" />
              A secure password is generated and emailed to this address. In development, open
              <a href="/dev/mailbox" class="link link-primary" target="_blank" rel="noopener">
                /dev/mailbox
              </a>
              to view the message.
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button type="button" phx-click="close" class="btn btn-ghost">Cancel</button>
              <button type="submit" class="btn btn-primary">
                {if @form.data.id, do: "Update user", else: "Create user"}
              </button>
            </div>
          </.form>
        </div>
      </div>

      <.live_component
        :if={@show_page_access && @access_user}
        module={CuzCoreConnectWeb.Admin.UserPageAccessComponent}
        id={"page-access-#{@access_user.id}"}
        user={@access_user}
      />
    </Layouts.user>
    """
  end
end
