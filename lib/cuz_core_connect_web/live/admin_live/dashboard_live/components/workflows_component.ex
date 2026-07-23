defmodule CuzCoreConnectWeb.AdminLiveWorkflowsComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Workflows

  @impl true
  def update(assigns, socket) do
    workflows = Map.get(assigns, :workflows) || Workflows.list_registration_workflows()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:workflows, workflows)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-base-100 shadow-lg rounded-box">
      <div class="px-4 py-5 sm:p-6">
        <div class="mb-6 flex items-center justify-between gap-3">
          <h3 class="text-lg font-semibold text-base-content">Workflow Management</h3>
          <.link navigate={~p"/admin/workflows/registration"} class="btn btn-sm btn-primary">
            Open workflows
          </.link>
        </div>

        <%= if @workflows == [] do %>
          <div class="rounded-box border-2 border-dashed border-base-300 p-10 text-center">
            <.icon name="hero-arrows-right-left" class="mx-auto mb-3 size-10 text-base-content/30" />
            <p class="text-base-content/60">No registration workflows yet.</p>
            <.link navigate={~p"/admin/workflows/registration"} class="btn btn-sm btn-primary mt-4">
              Create workflow
            </.link>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div
              :for={workflow <- @workflows}
              class="border border-base-300 rounded-box p-6 hover:shadow-lg transition-shadow"
            >
              <div class="flex items-center justify-between mb-4 gap-2">
                <h4 class="text-lg font-medium text-base-content truncate">{workflow.name}</h4>
                <span class={[
                  "badge badge-sm shrink-0",
                  workflow.is_active && "badge-success",
                  !workflow.is_active && "badge-neutral"
                ]}>
                  {if workflow.is_active, do: "Active", else: "Inactive"}
                </span>
              </div>
              <p class="text-sm text-base-content/70 mb-4 line-clamp-3">
                {workflow.description || "Student registration approval workflow"}
              </p>
              <div class="flex justify-between items-center">
                <span class="text-xs text-base-content/50">
                  {length(workflow.flow || [])} step(s)
                </span>
                <.link
                  navigate={~p"/admin/workflows/registration/#{workflow.id}/edit"}
                  class="text-primary text-sm font-medium"
                >
                  Manage
                </.link>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
