defmodule CuzCoreConnectWeb.Academics.Students.PendingRegistration do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registrations
  alias CuzCoreConnectWeb.Datatable.Pagination

  @filter_defaults %{
    search_filter: "",
    page: "",
    page_size: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Pending Registrations")
     |> assign(:id, "pending-registrations")
     |> assign(:search_placeholder, "Search pending registrations...")
     |> assign(:current_page, :students_pending)
     |> assign(:data_loader, true)
     |> assign(:data, [])
     |> assign(:selected_records, [])
     |> assign(:select_all, false)
     |> assign(:info_modal, false)
     |> assign(:error_modal, false)
     |> assign(:success_modal, false)
     |> assign(:error_message, "")
     |> assign(:session, socket.assigns[:session])
     |> Pagination.assign_filters(@filter_defaults)}
  end

  @impl true
  @spec handle_params(any(), any(), Phoenix.LiveView.Socket.t()) :: {:noreply, map()}
  def handle_params(params, _url, socket) do
    if connected?(socket), do: send(self(), {:fetch_registrations, params})

    {
      :noreply,
      socket
      |> Pagination.filter_composer(params)
      |> assign(:params, params)
    }
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
    data = Registrations.list_pending_registrations(Pagination.fetch_current_filters(socket))

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

  def handle_event("filter", %{"filters" => params}, socket) do
    socket =
      socket
      |> Pagination.filter_composer(params)
      |> Pagination.push_filters(~p"/admin/student/pending")

    {:noreply, socket}
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
    registration = Registrations.get_registration!(registration_id)

    Registrations.update_registration(registration, %{
      registration_status: "APPROVED",
      approval_level: "approved",
      payment_status: "APPROVED",
      financial_status: "APPROVED",
      accademics_status: "APPROVED",
      hod_status: "APPROVED",
      retention_status: "APPROVED"
    })
    |> case do
      {:ok, updated} ->
        Registrations.record_registration_action(
          updated,
          nil,
          "admin_override",
          "approved",
          "Approved by administrator"
        )

        {:ok, updated}

      error ->
        error
    end
  end

  defp reject_registration(registration_id) do
    registration = Registrations.get_registration!(registration_id)

    Registrations.update_registration(registration, %{
      registration_status: "REJECTED",
      approval_level: "rejected",
      rejection_reason: "Rejected by administrator",
      rejected_stage: "admin"
    })
    |> case do
      {:ok, updated} ->
        Registrations.record_registration_action(
          updated,
          nil,
          "admin_override",
          "rejected",
          "Rejected by administrator"
        )

        {:ok, updated}

      error ->
        error
    end
  end
end
