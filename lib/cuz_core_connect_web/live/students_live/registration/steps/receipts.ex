defmodule CuzCoreConnectWeb.Student.Registration.Steps.Receipts do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    registration = assigns.registration
    under_scholarship? = Map.get(registration, :under_scholarship, false) in [true, "true", "on"]

    form =
      to_form(
        %{
          "under_scholarship" => under_scholarship?,
          "scholarship_id" => Map.get(registration, :scholarship_id)
        },
        as: :receipt_step
      )

    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:upload_config, assigns.upload_config)
     |> assign(:scholarships, assigns.scholarships || [])
     |> assign(:scholarship_options, assigns.scholarship_options || [])
     |> assign(:under_scholarship?, under_scholarship?)
     |> assign(:error, nil)
     |> assign_new(:authenticated?, fn -> Map.get(assigns, :authenticated?, false) end)
     |> assign(:form, form)
     |> assign(:upload_form, to_form(%{}, as: :receipt_upload))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Payment & Scholarships</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Upload proof of payment, or declare a scholarship if your fees are covered.
      </p>

      <div class="mt-6 rounded-2xl border border-base-300 bg-base-100 p-5 shadow-sm">
        <.form
          for={@form}
          id="receipt-scholarship-form"
          phx-change="scholarship_change"
          phx-target={@myself}
          class="space-y-4"
        >
          <.input
            field={@form[:under_scholarship]}
            type="checkbox"
            label="I am under a scholarship"
          />

          <div :if={@under_scholarship?} class="space-y-2 pl-1">
            <%= if @scholarship_options == [] do %>
              <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
                No active scholarships are available yet. Contact the administration office, or upload a payment receipt instead.
              </div>
            <% else %>
              <.input
                field={@form[:scholarship_id]}
                type="select"
                label="Select scholarship"
                prompt="Choose a scholarship…"
                options={@scholarship_options}
                required
              />
              <p class="text-xs text-base-content/50">
                Choose the scholarship that covers your fees. You may still attach a receipt if required.
              </p>
            <% end %>
          </div>
        </.form>
      </div>

      <div class="mt-6">
        <label class="mb-2 block text-sm font-medium text-base-content">
          Payment Receipts
          <span :if={!@under_scholarship?} class="text-error">*</span>
          <span :if={@under_scholarship?} class="font-normal text-base-content/50">(optional)</span>
          <span class="mt-1 block text-xs font-normal text-base-content/50">
            JPG, JPEG, PNG, WEBP, or PDF. Max 5MB each, up to 3 files.
          </span>
        </label>

        <.form for={@upload_form} id="receipt-upload-form" phx-change="validate_upload">
          <div
            id="receipt-upload-dropzone"
            class="rounded-2xl border-2 border-dashed border-base-300 bg-base-200/40 p-6 text-center transition-colors hover:border-primary/50 hover:bg-primary/5"
            phx-drop-target={@upload_config.ref}
          >
            <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full border border-base-300 bg-base-100 shadow-sm">
              <.icon name="hero-arrow-up-tray" class="h-7 w-7 text-primary" />
            </div>
            <p class="mt-3 text-sm font-medium text-base-content">Drag and drop receipts here</p>
            <p class="mt-1 text-xs text-base-content/60">
              Or choose files from your device and wait for the upload to complete.
            </p>

            <div class="mt-4">
              <.live_file_input upload={@upload_config} class="btn btn-outline btn-sm" />
            </div>
          </div>
        </.form>

        <div class="mt-4 space-y-3">
          <%= for entry <- @upload_config.entries do %>
            <div
              id={"receipt-entry-#{entry.ref}"}
              class="flex items-center justify-between gap-4 rounded-xl border border-base-200 bg-base-100 px-4 py-3 shadow-sm"
            >
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2 text-sm text-base-content">
                  <.icon name="hero-paper-clip" class="h-4 w-4 text-base-content/50" />
                  <span class="truncate font-medium">{entry.client_name}</span>
                </div>
                <div class="mt-2 flex items-center gap-3">
                  <div class="h-1.5 flex-1 rounded-full bg-base-200">
                    <div
                      class="h-1.5 rounded-full bg-primary transition-all"
                      style={"width: #{entry.progress}%"}
                    />
                  </div>
                  <span class="text-xs font-medium text-base-content/60">
                    <%= if entry.done? do %>
                      Uploaded
                    <% else %>
                      {entry.progress}%
                    <% end %>
                  </span>
                </div>

                <%= for err <- upload_errors(@upload_config, entry) do %>
                  <p class="mt-2 text-xs text-error">
                    {entry.client_name}: {upload_error_to_string(err)}
                  </p>
                <% end %>
              </div>

              <button
                type="button"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                class="btn btn-ghost btn-sm text-base-content/50 hover:text-error"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </div>
          <% end %>
        </div>

        <div
          :if={!@under_scholarship? and Enum.empty?(@upload_config.entries)}
          class="mt-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
        >
          Upload at least one receipt to continue, or check that you are under a scholarship.
        </div>

        <p :if={@error} class="mt-3 text-sm text-error">{@error}</p>
      </div>

      <div class="mt-8 flex justify-between gap-3">
        <button type="button" phx-click="back" phx-target={@myself} class="btn btn-ghost">
          ← Back
        </button>
        <div class="flex gap-3">
          <button
            :if={@authenticated?}
            type="button"
            phx-click="save"
            phx-target={@myself}
            class="btn btn-outline"
          >
            Save
          </button>
          <button
            type="button"
            phx-click="next_receipt_step"
            phx-target={@myself}
            class="btn btn-primary px-8"
          >
            Review →
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("scholarship_change", %{"receipt_step" => params}, socket) do
    under? = checkbox_true?(params["under_scholarship"])
    scholarship_id = parse_id(params["scholarship_id"])

    scholarship_id = if under?, do: scholarship_id, else: nil

    form =
      to_form(
        %{
          "under_scholarship" => under?,
          "scholarship_id" => scholarship_id
        },
        as: :receipt_step
      )

    {:noreply,
     socket
     |> assign(:under_scholarship?, under?)
     |> assign(:form, form)
     |> assign(:error, nil)}
  end

  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    case step_payload(socket) do
      {:ok, payload} ->
        send(self(), {:save_step, payload})
        {:noreply, assign(socket, :error, nil)}

      {:error, message} ->
        {:noreply, assign(socket, :error, message)}
    end
  end

  def handle_event("next_receipt_step", _params, socket) do
    case step_payload(socket) do
      {:ok, payload} ->
        send(self(), {:next_step, payload})
        {:noreply, assign(socket, :error, nil)}

      {:error, message} ->
        {:noreply, assign(socket, :error, message)}
    end
  end

  defp step_payload(socket) do
    under? = socket.assigns.under_scholarship?
    scholarship_id = form_scholarship_id(socket.assigns.form)
    has_receipts? = socket.assigns.upload_config.entries != []

    cond do
      under? and is_nil(scholarship_id) ->
        {:error, "Please select a scholarship, or uncheck the scholarship option."}

      under? and socket.assigns.scholarship_options == [] ->
        {:error, "No scholarships are available. Upload a payment receipt instead."}

      not under? and not has_receipts? ->
        {:error, "Upload at least one payment receipt to continue."}

      true ->
        scholarship_name =
          if under? do
            Enum.find_value(socket.assigns.scholarships, fn s ->
              if s.id == scholarship_id, do: s.name
            end)
          end

        {:ok,
         %{
           under_scholarship: under?,
           scholarship_id: scholarship_id,
           scholarship_name: scholarship_name
         }}
    end
  end

  defp form_scholarship_id(form) do
    form[:scholarship_id].value
    |> case do
      nil -> nil
      "" -> nil
      value -> parse_id(value)
    end
  end

  defp checkbox_true?(value) when value in [true, "true", "on", "1"], do: true
  defp checkbox_true?(_), do: false

  defp parse_id(nil), do: nil
  defp parse_id(""), do: nil
  defp parse_id(id) when is_integer(id), do: id

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 5MB)."
  defp upload_error_to_string(:not_accepted), do: "Invalid file type."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 3)."
  defp upload_error_to_string(_), do: "Upload failed."
end
