defmodule CuzCoreConnectWeb.StudentLive.Dashboard.NewRegistrationComponent do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4">New Registration</h2>
      <div class="bg-base-200/40 rounded-xl p-6">
        <p class="text-base-content/60 mb-4">
          Ready to register? Click below to start a new course registration.
        </p>
        <%!-- Link to your actual registration form LiveView --%>
        <.link navigate={~p"/student/registrations/new"} class="btn btn-primary">
          <.icon name="hero-plus" class="h-4 w-4 mr-1" />
          Start Registration
        </.link>
      </div>
    </div>
    """
  end
end
