defmodule CuzCoreConnectWeb.Admin.Announcements.FormComponent do
  use CuzCoreConnectWeb, :live_component

  alias CuzCoreConnect.Academic

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Manage programme details</:subtitle>
      </.header>

      <.form
        for={@form}
        id="programme-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input field={@form[:code]} type="text" label="Code" required />
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:duration_years]} type="number" label="Duration (years)" min="1" max="10" />
        <.input field={@form[:is_active]} type="checkbox" label="Active" />

        <div class="flex justify-end space-x-2">
          <.link patch={~p"/admin/announcements"}>
            <.button>Cancel</.button>
          </.link>

          <.button phx-disable-with="Saving...">Save Programme</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{programme: programme} = assigns, socket) do
    changeset = Academic.change_program(programme)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"programmes" => program_params}, socket) do
    # Merge current params with existing programme data
    updated_program =
      socket.assigns.programme
      |> Map.merge(program_params, fn _k, v1, v2 ->
        if v2 == "" or v2 == nil, do: v1, else: v2
      end)

    changeset =
      updated_program
      |> Academic.change_program(program_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:programme, updated_program)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Fallback for direct params (no nesting)
    updated_program =
      socket.assigns.programme
      |> Map.merge(params, fn _k, v1, v2 ->
        if v2 == "" or v2 == nil, do: v1, else: v2
      end)

    changeset =
      updated_program
      |> Academic.change_program(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:programme, updated_program)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"programmes" => program_params}, socket) do
    save_program(socket, socket.assigns.action, program_params)
  end

  @impl true
  def handle_event("save", params, socket) do
    save_program(socket, socket.assigns.action, params)
  end

  defp save_program(socket, :edit, params) do
    case Academic.update_program(socket.assigns.programme, params) do
      {:ok, programme} ->
        notify_parent({:saved, programme})

        {:noreply,
         socket
         |> put_flash(:info, "Programme updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_program(socket, :new, params) do
    case Academic.create_program(params) do
      {:ok, programme} ->
        notify_parent({:saved, programme})

        {:noreply,
         socket
         |> put_flash(:info, "Programme created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
