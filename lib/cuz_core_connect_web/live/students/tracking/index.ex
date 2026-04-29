defmodule CuzCoreConnectWeb.Student.Tracking.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> assign(:tracking_number, "")
     |> assign(:registration, nil)
     |> assign(:searched, false)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_params(%{"tracking_number" => tracking_number}, _url, socket) do
    if tracking_number && tracking_number != "" do
      search_registration(socket, String.trim(tracking_number))
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(%{}, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search_tracking", %{"tracking_number" => tracking_number}, socket) do
    tracking_number = String.trim(tracking_number)

    socket =
      socket
      |> assign(:tracking_number, tracking_number)
      |> assign(:loading, true)
      |> assign(:searched, false)
      |> assign(:registration, nil)

    search_registration(socket, tracking_number)
  end

  # Private helper functions
  defp search_registration(socket, tracking_number) do
    case Registration.get_registration_by_tracking_number(tracking_number) do
      nil ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:searched, true)
         |> assign(:registration, nil)}

      registration ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:searched, true)
         |> assign(:registration, registration)}
    end
  end
end
