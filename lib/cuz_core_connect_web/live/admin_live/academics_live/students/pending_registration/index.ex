defmodule CuzCoreConnectWeb.Academics.Students.PendingRegistration do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registration
  alias CuzCoreConnect.Repo
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
    data = Registration.list_pending_registrations(Pagination.fetch_current_filters(socket))

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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <div class="mb-3">
        <h1 class="text-base font-bold tracking-wide text-slate-800">Pending Registrations</h1>
        <p class="mt-1 text-xs text-slate-500">
          A list of pending student registrations
        </p>
      </div>

      <!-- Data Loading State -->
      <%= if @data_loader do %>
        <div class="flex justify-center items-center py-12">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      <% else %>
        <!-- Data Table -->
        <.modern_table
          id="pending-registrations"
          rows={@data}
          class="shadow-sm"
          empty_state_title="No pending registrations"
          empty_state_description="No registrations found matching your criteria."
          show_header={false}
        >
          <:col :let={registration} label="Reference">
            <div class="font-bold">
              {registration.tracking_number || registration.student_id || registration.id}
            </div>
          </:col>
          <:col :let={registration} label="Student Name">
            <div>
              {registration.student_names}
            </div>
          </:col>
          <:col :let={registration} label="Date Issued">
            <div>
              {format_display_datetime(registration.registration_date)}
            </div>
          </:col>
          <:col :let={registration} label="Expiry Date">
            <div>
              {format_display_datetime(Date.add(DateTime.to_date(registration.registration_date), 364))}
            </div>
          </:col>
          <:col :let={registration} label="Status">
            <div class="uppercase">
              {registration.approval_level}
            </div>
          </:col>
          <:col :let={registration} label="Payment Status">
            <div class="uppercase">
              {registration.payment_status}
            </div>
          </:col>
          <:action :let={registration}>
            <.link
              navigate={"/registration/tracking/#{registration.tracking_number}"}
              class="inline-flex h-[29px] items-center rounded-md bg-primary px-3 text-xs text-primary-content transition duration-150 hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/20"
            >
              Options
            </.link>
          </:action>
        </.modern_table>

        <!-- Pagination Component -->
        <.live_component
          module={CuzCoreConnectWeb.Datatable.PaginationComponent}
          id="pagination"
          params={@params}
          pagination_data={@data}
        />
      <% end %>
    </Layouts.admin>

    """
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
end
