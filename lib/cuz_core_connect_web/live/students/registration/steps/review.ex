defmodule CuzCoreConnectWeb.Student.Registration.Steps.Review do
  use CuzCoreConnectWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> allow_upload(:receipt,
        accept: ~w(.jpg .jpeg .png .webp .pdf),
        max_entries: 3,
        max_file_size: 5_000_000  # 5MB
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold text-base-content">Review Your Registration</h2>
      <p class="text-sm text-base-content/70 mt-1">
        Please confirm all details before submitting.
      </p>

      <%!-- Summary cards --%>
      <div class="mt-6 space-y-4">

        <%!-- Program --%>
        <.review_row label="Program" value={@registration.program_name} />

        <%!-- Semester --%>
        <.review_row
          label="Semester"
          value={"Semester #{@registration.semester}, Academic Year #{@registration.academic_year}, Intake #{@registration.intake}"}
        />

        <%!-- Courses --%>
        <div class="flex gap-4 py-3 border-b border-base-200">
          <span class="w-32 shrink-0 text-sm font-medium text-base-content/70">Courses</span>
          <div class="flex-1 space-y-2">
            <%= for course <- @registration.courses do %>
              <div class="flex justify-between text-sm">
                <span class="text-base-content">
                  <span class="font-mono text-xs text-base-content/40 mr-2">{course.code}</span>
                  {course.name}
                </span>
                <span class="text-base-content/60 shrink-0 ml-4">{course.credit_hours} cr</span>
              </div>
            <% end %>

            <div class="pt-2 border-t border-base-200 flex justify-between text-sm font-semibold">
              <span class="text-base-content/80">Total Credit Hours</span>
              <span class="text-primary">
                {Enum.sum(Enum.map(@registration.courses, & &1.credit_hours))}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">
          Payment Receipt
          <span class="text-gray-400 font-normal">(JPG, PNG, PDF — max 5MB each, up to 3 files)</span>
        </label>

        <div
          class="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:border-primary/50 transition-colors"
          phx-drop-target={@uploads.receipt.ref}
          phx-target={@myself}
        >
          <.icon name="hero-arrow-up-tray" class="w-8 h-8 text-gray-400 mx-auto mb-2" />
          <p class="text-sm text-gray-500">Drag & drop files here, or</p>
          <label class="mt-2 cursor-pointer inline-block">
            <.live_file_input upload={@uploads.receipt} class="sr-only" phx-target={@myself} />
            <span class="btn btn-sm btn-outline mt-2">Browse files</span>
          </label>
        </div>

        <%!-- Upload errors --%>
        <%= for entry <- @uploads.receipt.entries do %>
          <%= for err <- upload_errors(@uploads.receipt, entry) do %>
            <p class="mt-1 text-xs text-red-500">
              {entry.client_name}: {upload_error_to_string(err)}
            </p>
          <% end %>
        <% end %>

        <%!-- File previews --%>
        <div class="mt-3 space-y-2">
          <%= for entry <- @uploads.receipt.entries do %>
            <div class="flex items-center justify-between px-3 py-2 bg-gray-50 rounded-lg border border-gray-200">
              <div class="flex items-center gap-2">
                <.icon name="hero-paper-clip" class="w-4 h-4 text-gray-400" />
                <span class="text-sm text-gray-700">{entry.client_name}</span>
                <span class="text-xs text-gray-400">
                  {Float.round(entry.client_size / 1_000, 1)} KB
                </span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-200 rounded-full h-1.5">
                  <div
                    class="bg-primary h-1.5 rounded-full transition-all"
                    style={"width: #{entry.progress}%"}
                  />
                </div>
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="text-gray-400 hover:text-red-500"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-8 flex justify-between">
        <button type="button" phx-click="back" phx-target={@myself} class="btn btn-ghost">
          ← Back
        </button>
        <button type="button" phx-click="submit" phx-target={@myself} class="btn btn-primary px-8">
          <.icon name="hero-check-circle" class="w-5 h-5 mr-1" /> Submit Registration
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt, ref)}
  end

  def handle_event("submit", _params, socket) do
    # Consume uploads and collect metadata to send up to the wizard
    uploaded_files =
      consume_uploaded_entries(socket, :receipt, fn %{path: tmp_path}, entry ->
        # Build a unique storage key
        ext = Path.extname(entry.client_name)
        key = "receipts/#{Date.utc_today().year}/#{Ecto.UUID.generate()}#{ext}"

        # TODO: swap this for S3 in prod, e.g. ExAws.S3.upload
        dest = Path.join([:code.priv_dir(:cuz_core_connect), "static", "uploads", key])
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(tmp_path, dest)

        {:ok, %{
          original_filename: entry.client_name,
          storage_key: key,
          content_type: entry.client_type,
          file_size: entry.client_size
        }}
      end)

    send(self(), {:next_step, %{uploaded_receipts: uploaded_files}})
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :receipt, ref)}
  end

  def handle_event("back", _params, socket) do
    send(self(), :prev_step)
    {:noreply, socket}
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp review_row(assigns) do
    ~H"""
    <div class="flex gap-4 py-3 border-b border-base-200">
      <span class="w-32 shrink-0 text-sm font-medium text-base-content/70">{@label}</span>
      <span class="text-sm text-base-content">{@value}</span>
    </div>
    """
  end

  defp upload_error_to_string(:too_large),    do: "File is too large (max 5MB)."
  defp upload_error_to_string(:not_accepted), do: "Invalid file type."
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 3)."
  defp upload_error_to_string(_),             do: "Upload failed."
end
