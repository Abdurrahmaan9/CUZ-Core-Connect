defmodule CuzCoreConnectWeb.Student.Registration.Steps.Receipts do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:upload_config, assigns.upload_config)
     |> assign(:form, to_form(%{}, as: :receipt_upload))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Upload Payment Receipts</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Attach at least one proof of payment before moving to the final review step.
      </p>

      <div class="mt-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">
          Payment Receipts <span class="text-red-500">*</span>
          <span class="text-gray-400 font-normal block text-xs mt-1">
            JPG, JPEG, PNG, WEBP, or PDF. Max 5MB each, up to 3 files.
          </span>
        </label>

        <.form for={@form} id="receipt-upload-form" phx-change="validate_upload">
          <div
            id="receipt-upload-dropzone"
            class="border-2 border-dashed border-gray-300 rounded-2xl p-6 text-center bg-gray-50/60 hover:border-primary/50 hover:bg-primary/5 transition-colors"
            phx-drop-target={@upload_config.ref}
          >
            <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-white shadow-sm border border-gray-200">
              <.icon name="hero-arrow-up-tray" class="w-7 h-7 text-primary" />
            </div>
            <p class="mt-3 text-sm font-medium text-base-content">Drag and drop receipts here</p>
            <p class="mt-1 text-xs text-base-content/60">Or choose files from your device and wait for the upload to complete.</p>

            <div class="mt-4">
              <.live_file_input
                upload={@upload_config}
                class="btn btn-outline btn-sm"
              />
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
                  <.icon name="hero-paper-clip" class="w-4 h-4 text-base-content/50" />
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
                <.icon name="hero-x-mark" class="w-4 h-4" />
              </button>
            </div>
          <% end %>
        </div>

        <%= if Enum.empty?(@upload_config.entries) do %>
          <div class="mt-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            Upload at least one receipt to continue.
          </div>
        <% end %>
      </div>

      <div class="mt-8 flex justify-between">
        <button type="button" phx-click="back" phx-target={@myself} class="btn btn-ghost">
          ← Back
        </button>
        <button type="button" phx-click="next_receipt_step" class="btn btn-primary px-8">
          Review →
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 5MB)."
  defp upload_error_to_string(:not_accepted), do: "Invalid file type."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 3)."
  defp upload_error_to_string(_), do: "Upload failed."
end
