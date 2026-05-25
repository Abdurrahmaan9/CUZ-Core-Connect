defmodule CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Academic
  alias CuzCoreConnect.Academics.Programmes, as: Programme
  alias CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:programmes, Academic.list_programs())
     |> assign(
       page_title: "Programmes",
       current_page: :programmes_management
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Programme")
    |> assign(:programme, Academic.get_program!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Programme")
    |> assign(:programme, %Programme{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Programmes")
    |> assign(:programme, nil)
  end

  @impl true
  def handle_info({CuzCoreConnectWeb.Admin.AcademicManagement.Programmes.FormComponent, {:saved, programme}}, socket) do
    {:noreply, stream_insert(socket, :programmes, programme)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    programme = Academic.get_program!(id)
    {:ok, _} = Academic.delete_program(programme)

    {:noreply, stream_delete(socket, :programmes, programme)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} page_title={@page_title} current_page={@current_page}>
      <.header>
        Programmes
        <:subtitle>Manage academic programmes in the system</:subtitle>
        <:actions>
          <.link patch={~p"/admin/student/programmes/new"}>
            <.button>New Programme</.button>
          </.link>
        </:actions>
      </.header>

      <.modern_table
          id="programmes"
          rows={@streams.programmes}
          class="shadow-sm"
          empty_state_title="No programmes found"
          empty_state_description="No programmes have been created yet."
          row_click={fn {_id, programme} -> JS.navigate(~p"/admin/student/programmes/#{programme}/edit") end}
        >
          <:col :let={{_id, programme}} label="Code"><%= programme.code %></:col>
          <:col :let={{_id, programme}} label="Name"><%= programme.name %></:col>
          <:col :let={{_id, programme}} label="Duration"><%= programme.duration_years %> years</:col>
          <:col :let={{_id, programme}} label="Status">
            <span class={[
              "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
              programme.is_active && "bg-green-100 text-green-800",
              !programme.is_active && "bg-gray-100 text-gray-800"
            ]}>
              <%= if programme.is_active, do: "Active", else: "Inactive" %>
            </span>
          </:col>
          <:action :let={{_id, programme}}>
            <div class="sr-only">
              <.link navigate={~p"/admin/student/programmes/#{programme}"}>Show</.link>
            </div>
            <.link patch={~p"/admin/student/programmes/#{programme}/edit"}>
              <.button>Edit</.button>
            </.link>
          </:action>
          <:action :let={{id, programme}}>
            <.link
              phx-click={JS.push("delete", value: %{id: programme.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              <.button class="bg-red-600 hover:bg-red-700 text-white">Delete</.button>
            </.link>
          </:action>
        </.modern_table>

      <div :if={@live_action in [:new, :edit]} class="fixed inset-0 z-50 overflow-y-auto">
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" aria-hidden="true"></div>
      <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0 relative z-10">
        <div class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
          <div class="bg-white px-4 pb-4 pt-5 sm:p-6 sm:pb-4">
            <.live_component
              module={FormComponent}
              id={@programme.id || :new}
              title={@page_title}
              action={@live_action}
              programme={@programme}
              patch={~p"/admin/student/programmes"}
            />
          </div>
        </div>
      </div>
    </div>
    </Layouts.admin>
    """
  end
end
