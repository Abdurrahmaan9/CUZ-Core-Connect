defmodule CuzCoreConnectWeb.Academics.Students.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration
  alias CuzCoreConnect.Repo
  alias CuzCoreConnectWeb.Helps.PaginationControl, as: Control

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    {:ok,
     socket
     |> assign(:data_loader, true)
     |> assign(:data, [])
     |> assign(:selected_records, [])
     |> assign(:select_all, false)
     |> assign(:info_modal, false)
     |> assign(:error_modal, false)
     |> assign(:success_modal, false)
     |> assign(:error_message, "")
     |> assign(:session, socket.assigns[:session])
     |> assign(
       page_title: "Pending Registrations",
       current_page: :student_pending,
       current_scope: current_scope
     )
     |> Control.order_by_composer()
     |> Control.i_search_composer()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:fetch_registrations, params})

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Pending Registrations")
    |> assign(:info_modal, false)
  end

  @impl true
  def handle_info({:fetch_registrations, params}, socket) do
    fetch_registrations(socket, params)
  end

  @impl true
  def handle_info(data, socket), do: handle_info_switch(socket, data)

  defp handle_info_switch(socket, {:fetch_registrations, params}) do
    fetch_registrations(socket, params)
  end

  defp fetch_registrations(socket, params) do
    data = Registration.list_pending_registrations(Control.create_table_params(socket, params))

    {
      :noreply,
      assign(socket, :data, data)
      |> assign(:data_loader, false)
      |> assign(:params, params)
    }
  end

  @impl true
  def handle_event("iSearch", params, socket) do
    fetch_registrations(socket, params)
  end

  def handle_event("filter", params, socket) do
    fetch_registrations(socket, params)
  end

  def handle_event("approve_registration", %{"registration-id" => registration_id}, socket) do
    case approve_registration(registration_id) do
      {:ok, _registration} ->
        send(self(), {:fetch_registrations, socket.assigns.params})
        {:noreply, socket |> put_flash(:info, "Registration approved successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to approve registration")}
    end
  end

  @impl true
  def handle_event("reject_registration", %{"registration-id" => registration_id}, socket) do
    case reject_registration(registration_id) do
      {:ok, _registration} ->
        send(self(), {:fetch_registrations, socket.assigns.params})
        {:noreply, socket |> put_flash(:info, "Registration rejected")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject registration")}
    end
  end

  defp approve_registration(registration_id) do
    registration = Repo.get(Registration, registration_id)

    registration
    |> Ecto.Changeset.change(%{
      approval_level: "approved",
      approved_by: %{
        # Will be set with current user when auth is implemented
        user_id: nil,
        approved_at: DateTime.utc_now(),
        notes: "Approved by administrator"
      }
    })
    |> Repo.update()
  end

  defp reject_registration(registration_id) do
    registration = Repo.get(Registration, registration_id)

    registration
    |> Ecto.Changeset.change(%{
      approval_level: "rejected",
      approved_by: %{
        # Will be set with current user when auth is implemented
        user_id: nil,
        approved_at: DateTime.utc_now(),
        notes: "Rejected by administrator"
      }
    })
    |> Repo.update()
  end

  # defp get_program_name(program_details) when is_map(program_details) do
  #   Map.get(program_details, "program_name", "Not specified")
  # end

  # defp get_program_name(_), do: "Not specified"

  defp format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> format_date()
  end

  defp format_date(%Date{} = date) do
    "#{date.day}#{ordinal_suffix(date.day)} #{Calendar.strftime(date, "%B %Y")}"
  end

  defp format_date(_), do: "Unknown"

  defp format_expiry_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.add(364)
    |> format_date()
  end

  defp format_expiry_date(_), do: "Unknown"

  defp ordinal_suffix(day) when day in 11..13, do: "th"
  defp ordinal_suffix(day) when rem(day, 10) == 1, do: "st"
  defp ordinal_suffix(day) when rem(day, 10) == 2, do: "nd"
  defp ordinal_suffix(day) when rem(day, 10) == 3, do: "rd"
  defp ordinal_suffix(_day), do: "th"
end
