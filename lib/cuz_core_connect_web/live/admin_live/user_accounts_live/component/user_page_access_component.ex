defmodule CuzCoreConnectWeb.Admin.UserPageAccessComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Pages
  # alias CuzCoreConnect.Pages.Page

  @impl true
  def update(%{user: user} = assigns, socket) do
    role_pages = Pages.list_pages_for_role(user.user_role)
    user_access = Pages.build_access_map(user.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:role_pages, role_pages)
     |> assign(:user_access, user_access)}
  end

  @impl true
  def handle_event("toggle_page", %{"page-id" => page_id, "page-name" => page_name}, socket) do
    user = socket.assigns.user

    if Map.has_key?(socket.assigns.user_access, page_name) do
      page = Enum.find(socket.assigns.role_pages, &(to_string(&1.id) == page_id))
      Pages.revoke_page_access(user.id, page.id)
    else
      page = Enum.find(socket.assigns.role_pages, &(to_string(&1.id) == page_id))
      Pages.grant_page_access(user.id, page.id, page.actions)
    end

    user_access = Pages.build_access_map(user.id)
    {:noreply, assign(socket, :user_access, user_access)}
  end

  def handle_event("update_actions", %{"page-id" => page_id, "page-name" => _page_name, "actions" => actions}, socket) do
    user = socket.assigns.user
    page = Enum.find(socket.assigns.role_pages, &(to_string(&1.id) == page_id))

    actions_list = Map.keys(actions) |> Enum.filter(&(actions[&1] == "true"))
    Pages.update_user_page_actions(user.id, page.id, actions_list)

    user_access = Pages.build_access_map(user.id)
    {:noreply, assign(socket, :user_access, user_access)}
  end

  @impl true
  def handle_event("cancel_form_component", _, socket) do
    notify_parent(:cancel_form_component, "Form closed")
    {:noreply, socket}
  end

  defp notify_parent(key, msg), do: send(self(), {__MODULE__, {key, msg}})

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.modal id={"#{@id}-modal"} show on_cancel={JS.push("cancel_form_component", target: @myself) |> JS.exec("phx-remove", to: "##{@id}-modal")}>
        <:title>
          <h3 class="font-semibold text-base">
            Page Access for <span class="text-primary">{@user.email}</span>
            <span class="badge badge-sm badge-outline ml-2">{@user.user_role}</span>
          </h3>
        </:title>

        <div class="space-y-4">

          <%= if Enum.empty?(@role_pages) do %>
            <p class="text-sm text-base-content/50">No pages defined for this role.</p>
          <% else %>
            <div class="space-y-3">
              <%= for page <- @role_pages do %>
                <% has_access = Map.has_key?(@user_access, page.name) %>
                <% current_actions = Map.get(@user_access, page.name, []) %>
                <div class={"rounded-lg border p-4 #{if has_access, do: "border-primary/30 bg-base-200/40", else: "border-base-300 opacity-60"}"}>
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1">
                      <div class="flex items-center gap-2">
                        <input
                          type="checkbox"
                          class="checkbox checkbox-sm checkbox-primary"
                          checked={has_access}
                          phx-click="toggle_page"
                          phx-value-page-id={page.id}
                          phx-value-page-name={page.name}
                          phx-target={@myself}
                        />
                        <span class="font-medium text-sm">{page.name}</span>
                      </div>
                      <p class="text-xs text-base-content/50 mt-0.5 ml-6">{page.description}</p>
                    </div>

                    <%= if has_access do %>
                      <div class="flex flex-wrap gap-2">
                        <%= for action <- ~w(view create edit delete export) do %>
                          <% checked = action in current_actions %>
                          <% available = action in page.actions %>
                          <%= if available do %>
                            <label class="flex items-center gap-1 text-xs cursor-pointer">
                              <input
                                type="checkbox"
                                class="checkbox checkbox-xs"
                                checked={checked}
                                phx-click="update_actions"
                                phx-value-page-id={page.id}
                                phx-value-page-name={page.name}
                                phx-value-actions={Jason.encode!(if checked, do: List.delete(current_actions, action), else: current_actions ++ [action])}
                                phx-target={@myself}
                              />
                              {action}
                            </label>
                          <% end %>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </.modal>
    </div>
    """
  end
end
