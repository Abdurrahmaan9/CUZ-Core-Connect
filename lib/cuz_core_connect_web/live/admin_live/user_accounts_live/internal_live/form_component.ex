defmodule CuzCoreConnectWeb.Admin.UserAccounts.Internal.FormComponent do
  @moduledoc false
  # Create/edit is handled by the parent LiveView modal.
  use CuzCoreConnectWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="hidden"></div>
    """
  end
end
