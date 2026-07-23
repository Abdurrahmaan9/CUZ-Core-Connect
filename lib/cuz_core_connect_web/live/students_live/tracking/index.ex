defmodule CuzCoreConnectWeb.Student.Tracking.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registrations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Track Registration")
     |> assign(:current_page, :student_registration_tracking)
     |> assign(:tracking_number, "")
     |> assign(:registration, nil)
     |> assign(:searched, false)
     |> assign(:show_mobile_menu, false)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_params(%{"tracking_number" => tracking_number}, _url, socket) do
    tracking_number = String.trim(tracking_number || "")

    if tracking_number != "" do
      search_registration(assign(socket, :tracking_number, tracking_number), tracking_number)
    else
      {:noreply, socket}
    end
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

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

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:tracking_number, "")
     |> assign(:registration, nil)
     |> assign(:searched, false)
     |> assign(:loading, false)
     |> push_patch(to: ~p"/registration/tracking")}
  end

  defp search_registration(socket, tracking_number) do
    case Registrations.get_registration_by_tracking_number(tracking_number) do
      nil ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:searched, true)
         |> assign(:registration, nil)}

      registration ->
        socket =
          socket
          |> assign(:loading, false)
          |> assign(:searched, true)
          |> assign(:registration, registration)

        current_path = socket.assigns[:live_action]

        # Avoid re-patching when already on the show route for this tracking number
        # (handle_params already loaded it).
        if current_path == :show and socket.assigns.tracking_number == registration.tracking_number do
          {:noreply, socket}
        else
          {:noreply, push_patch(socket, to: ~p"/registration/tracking/#{registration.tracking_number}")}
        end
    end
  end

  defp logged_in?(assigns) do
    match?(%{user: %{id: _}}, assigns[:current_scope])
  end

  defp overall_status(registration) do
    cond do
      registration.registration_status in ["APPROVED", "REJECTED", "PENDING"] ->
        registration.registration_status

      registration.approval_level in ["approved", "rejected", "pending"] ->
        String.upcase(registration.approval_level)

      true ->
        "PENDING"
    end
  end

  defp overall_label("APPROVED"), do: "Approved"
  defp overall_label("REJECTED"), do: "Rejected"
  defp overall_label(_), do: "Pending"

  defp overall_badge_class("APPROVED"), do: "bg-success/15 text-success border-success/30"
  defp overall_badge_class("REJECTED"), do: "bg-error/15 text-error border-error/30"
  defp overall_badge_class(_), do: "bg-warning/15 text-warning border-warning/30"

  defp overall_icon("APPROVED"), do: "hero-check-badge"
  defp overall_icon("REJECTED"), do: "hero-x-circle"
  defp overall_icon(_), do: "hero-clock"

  defp stage_status_icon("APPROVED"), do: "hero-check-circle"
  defp stage_status_icon("REJECTED"), do: "hero-x-circle"
  defp stage_status_icon(_), do: "hero-clock"

  defp stage_tone("APPROVED"), do: "border-success/40 bg-success/10 text-success"
  defp stage_tone("REJECTED"), do: "border-error/40 bg-error/10 text-error"
  defp stage_tone(_), do: "border-warning/40 bg-warning/10 text-warning"

  defp stage_connector("APPROVED"), do: "bg-success"
  defp stage_connector("REJECTED"), do: "bg-error"
  defp stage_connector(_), do: "bg-base-300"

  defp payment_label("APPROVED"), do: "Verified"
  defp payment_label("REJECTED"), do: "Rejected"
  defp payment_label(_), do: "Pending"

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y · %H:%M")
  defp format_datetime(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y · %H:%M")
  defp format_datetime(_), do: "—"

  defp approval_stages(registration) do
    [
      %{
        key: "finance",
        label: "Payment",
        icon: "hero-banknotes",
        status: registration.payment_status
      },
      %{
        key: "academics",
        label: "Academics",
        icon: "hero-academic-cap",
        status: registration.accademics_status
      },
      %{
        key: "hod",
        label: "HOD",
        icon: "hero-building-office-2",
        status: registration.hod_status
      },
      %{
        key: "retention",
        label: "Retention",
        icon: "hero-clipboard-document-check",
        status: registration.retention_status
      }
    ]
  end

  defp program_detail(registration, key) do
    details = registration.student_program_details || %{}
    Map.get(details, key) || Map.get(details, to_string(key))
  end

  defp selected_courses(registration) do
    courses = registration.student_courses || %{}
    Map.get(courses, "selected_courses") || Map.get(courses, :selected_courses) || []
  end

  defp total_credits(registration) do
    courses = registration.student_courses || %{}
    Map.get(courses, "total_credit_hours") || Map.get(courses, :total_credit_hours) || 0
  end

  @impl true
  def render(assigns) do
    overall = if assigns.registration, do: overall_status(assigns.registration), else: nil
    stages = if assigns.registration, do: approval_stages(assigns.registration), else: []

    assigns =
      assigns
      |> assign(:logged_in?, logged_in?(assigns))
      |> assign(:overall, overall)
      |> assign(:stages, stages)

    ~H"""
    <%= if @logged_in? do %>
      <Layouts.user
        flash={@flash}
        current_scope={@current_scope}
        page_title={@page_title}
        current_page={@current_page}
      >
        <.tracking_body {assigns} />
      </Layouts.user>
    <% else %>
      <Layouts.unauth flash={@flash} current_scope={@current_scope}>
        <:header>
          <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
        </:header>
        <.tracking_body {assigns} />
        <:footer>
          <CuzCoreConnectWeb.Navigations.Unauth.footer />
        </:footer>
      </Layouts.unauth>
    <% end %>
    """
  end

  defp tracking_body(assigns) do
    ~H"""
    <div class={[
      "mx-auto px-4 sm:px-6",
      @logged_in? && "max-w-5xl py-2",
      !@logged_in? && "max-w-5xl py-8 sm:py-12"
    ]}>
      <div class="relative overflow-hidden rounded-3xl border border-base-300/70 bg-gradient-to-br from-base-100 via-base-100 to-primary/5 shadow-sm">
        <div class="pointer-events-none absolute -right-16 -top-16 size-56 rounded-full bg-primary/10 blur-3xl">
        </div>
        <div class="pointer-events-none absolute -bottom-20 -left-10 size-48 rounded-full bg-secondary/10 blur-3xl">
        </div>

        <div class="relative p-5 sm:p-8 lg:p-10 space-y-8">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div class="space-y-2">
              <div class="inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                <.icon name="hero-bolt" class="size-3.5" /> Live status check
              </div>
              <h1 class="text-2xl sm:text-3xl font-bold tracking-tight text-base-content">
                Track Your Registration
              </h1>
              <p class="max-w-xl text-sm sm:text-base text-base-content/65">
                Enter your tracking number to see approval progress across payment, academics, HOD, and retention.
              </p>
            </div>
          </div>

          <form
            id="tracking-search-form"
            phx-submit="search_tracking"
            class="flex flex-col gap-3 sm:flex-row"
          >
            <label class="sr-only" for="tracking_number">Tracking number</label>
            <div class="relative flex-1">
              <.icon
                name="hero-magnifying-glass"
                class="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-base-content/40"
              />
              <input
                type="text"
                name="tracking_number"
                id="tracking_number"
                value={@tracking_number}
                placeholder="e.g. REG-17143584000-a1b2c3"
                autocomplete="off"
                required
                class="w-full rounded-2xl border border-base-300 bg-base-100 py-3.5 pl-11 pr-4 text-sm sm:text-base shadow-sm transition focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            </div>
            <button
              type="submit"
              phx-disable-with="Searching..."
              class="inline-flex items-center justify-center gap-2 rounded-2xl bg-primary px-6 py-3.5 text-sm font-semibold text-primary-content shadow-sm transition hover:bg-primary/90 active:scale-[0.98]"
            >
              <.icon name="hero-magnifying-glass" class="size-5" /> Track
            </button>
            <button
              :if={@searched}
              type="button"
              phx-click="clear_search"
              class="inline-flex items-center justify-center gap-2 rounded-2xl border border-base-300 bg-base-100 px-5 py-3.5 text-sm font-medium text-base-content/70 transition hover:bg-base-200"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Clear
            </button>
          </form>

          <div :if={@loading} class="flex flex-col items-center justify-center gap-3 py-14">
            <span class="loading loading-spinner loading-lg text-primary"></span>
            <p class="text-sm text-base-content/60">Looking up your registration…</p>
          </div>

          <div :if={@searched && !@loading} class="space-y-6">
            <%= if @registration do %>
              <div class={[
                "flex flex-col gap-4 rounded-2xl border p-4 sm:flex-row sm:items-center sm:justify-between sm:p-5",
                overall_badge_class(@overall)
              ]}>
                <div class="flex items-start gap-3">
                  <div class="rounded-xl bg-base-100/70 p-2.5 shadow-sm">
                    <.icon name={overall_icon(@overall)} class="size-6" />
                  </div>
                  <div>
                    <p class="text-xs font-medium uppercase tracking-wide opacity-70">
                      Approval Status
                    </p>
                    <p class="text-xl font-bold">{overall_label(@overall)}</p>
                    <p class="mt-1 font-mono text-xs sm:text-sm opacity-80">
                      {@registration.tracking_number}
                    </p>
                  </div>
                </div>
                <div class="flex flex-wrap gap-2 text-xs sm:justify-end">
                  <span class="inline-flex items-center gap-1.5 rounded-full border border-current/20 bg-base-100/50 px-3 py-1.5">
                    <.icon name="hero-calendar-days" class="size-3.5" />
                    Submitted {format_datetime(@registration.registration_date || @registration.inserted_at)}
                  </span>
                  <span class="inline-flex items-center gap-1.5 rounded-full border border-current/20 bg-base-100/50 px-3 py-1.5">
                    <.icon name="hero-banknotes" class="size-3.5" />
                    Payment {payment_label(@registration.payment_status)}
                  </span>
                </div>
              </div>

              <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
                <div class="mb-5 flex items-center gap-2">
                  <.icon name="hero-arrows-right-left" class="size-5 text-primary" />
                  <h2 class="text-base font-semibold sm:text-lg">Approval Pipeline</h2>
                </div>

                <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  <div
                    :for={{stage, idx} <- Enum.with_index(@stages)}
                    id={"stage-#{stage.key}"}
                    class={[
                      "relative rounded-2xl border p-4 transition duration-200 hover:-translate-y-0.5 hover:shadow-md",
                      stage_tone(stage.status)
                    ]}
                  >
                    <div
                      :if={idx < length(@stages) - 1}
                      class={[
                        "absolute right-[-0.4rem] top-1/2 hidden h-0.5 w-3 -translate-y-1/2 lg:block",
                        stage_connector(stage.status)
                      ]}
                    >
                    </div>
                    <div class="mb-3 flex items-center justify-between">
                      <div class="rounded-xl bg-base-100/70 p-2">
                        <.icon name={stage.icon} class="size-5" />
                      </div>
                      <.icon name={stage_status_icon(stage.status)} class="size-5" />
                    </div>
                    <p class="text-sm font-semibold">{stage.label}</p>
                    <p class="mt-1 text-xs font-medium uppercase tracking-wide opacity-80">
                      {String.capitalize(String.downcase(stage.status || "pending"))}
                    </p>
                  </div>
                </div>

                <div
                  :if={@overall == "REJECTED"}
                  class="mt-5 rounded-xl border border-error/30 bg-error/10 p-4 text-sm text-error"
                >
                  <div class="flex items-start gap-2">
                    <.icon name="hero-exclamation-triangle" class="mt-0.5 size-5 shrink-0" />
                    <div>
                      <p class="font-semibold">
                        Rejected at {String.capitalize(@registration.rejected_stage || "a stage")}
                      </p>
                      <p class="mt-1 opacity-90">
                        {@registration.rejection_reason || "No reason was provided."}
                      </p>
                    </div>
                  </div>
                </div>

                <div
                  :if={@overall == "APPROVED"}
                  class="mt-5 flex flex-col gap-3 rounded-xl border border-success/30 bg-success/10 p-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div class="flex items-start gap-2 text-success">
                    <.icon name="hero-check-badge" class="mt-0.5 size-5 shrink-0" />
                    <div>
                      <p class="text-sm font-medium">
                        Registration fully approved
                      </p>
                      <p class="mt-0.5 text-xs opacity-80">
                        View or print your official Proof of Registration.
                      </p>
                    </div>
                  </div>
                  <div class="flex flex-wrap gap-2 sm:justify-end">
                    <.link
                      href={~p"/registration/tracking/#{@registration.tracking_number}/proof"}
                      target="_blank"
                      class="inline-flex items-center justify-center gap-2 rounded-xl border border-success/40 bg-base-100 px-4 py-2 text-sm font-semibold text-success transition hover:bg-success/10"
                    >
                      <.icon name="hero-eye" class="size-4" /> View Proof
                    </.link>
                    <.link
                      href={~p"/registration/tracking/#{@registration.tracking_number}/proof"}
                      target="_blank"
                      class="inline-flex items-center justify-center gap-2 rounded-xl bg-success px-4 py-2 text-sm font-semibold text-success-content transition hover:bg-success/90"
                    >
                      <.icon name="hero-arrow-down-tray" class="size-4" /> Download / Print
                    </.link>
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
                <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
                  <div class="mb-4 flex items-center gap-2">
                    <.icon name="hero-user-circle" class="size-5 text-primary" />
                    <h2 class="text-base font-semibold">Student</h2>
                  </div>
                  <dl class="space-y-3 text-sm">
                    <div class="flex items-start justify-between gap-4 border-b border-base-200 pb-3">
                      <dt class="text-base-content/55">Student number</dt>
                      <dd class="font-mono font-semibold text-right">{@registration.student_id}</dd>
                    </div>
                    <div class="flex items-start justify-between gap-4 border-b border-base-200 pb-3">
                      <dt class="text-base-content/55">Name</dt>
                      <dd class="font-medium text-right">{@registration.student_names}</dd>
                    </div>
                    <div class="flex items-start justify-between gap-4">
                      <dt class="text-base-content/55">Email</dt>
                      <dd class="text-right break-all">{@registration.student_email}</dd>
                    </div>
                  </dl>
                </div>

                <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
                  <div class="mb-4 flex items-center gap-2">
                    <.icon name="hero-building-library" class="size-5 text-primary" />
                    <h2 class="text-base font-semibold">Programme</h2>
                  </div>
                  <dl class="space-y-3 text-sm">
                    <div class="flex items-start justify-between gap-4 border-b border-base-200 pb-3">
                      <dt class="text-base-content/55">Programme</dt>
                      <dd class="font-medium text-right">
                        {program_detail(@registration, "program_name") || "—"}
                      </dd>
                    </div>
                    <div class="flex items-start justify-between gap-4 border-b border-base-200 pb-3">
                      <dt class="text-base-content/55">Academic year</dt>
                      <dd class="text-right">
                        {program_detail(@registration, "academic_year") || "—"}
                      </dd>
                    </div>
                    <div class="flex items-start justify-between gap-4">
                      <dt class="text-base-content/55">Semester</dt>
                      <dd class="text-right">{program_detail(@registration, "semester") || "—"}</dd>
                    </div>
                  </dl>
                </div>
              </div>

              <div
                :if={selected_courses(@registration) != []}
                class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6"
              >
                <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
                  <div class="flex items-center gap-2">
                    <.icon name="hero-book-open" class="size-5 text-primary" />
                    <h2 class="text-base font-semibold">Registered Courses</h2>
                  </div>
                  <span class="inline-flex items-center gap-1.5 rounded-full bg-secondary/10 px-3 py-1 text-xs font-semibold text-secondary">
                    <.icon name="hero-academic-cap" class="size-3.5" />
                    {total_credits(@registration)} credit hours
                  </span>
                </div>

                <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  <div
                    :for={course <- selected_courses(@registration)}
                    class="rounded-xl border border-base-200 bg-base-200/30 p-3.5 transition hover:border-primary/30 hover:bg-primary/5"
                  >
                    <div class="mb-1.5 flex items-start justify-between gap-2">
                      <span class="font-mono text-xs font-semibold text-primary">
                        {course["code"] || course[:code]}
                      </span>
                      <span class="text-xs text-base-content/50">
                        {course["credits"] || course[:credits]} cr
                      </span>
                    </div>
                    <p class="text-sm font-medium leading-snug">
                      {course["name"] || course[:name]}
                    </p>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="rounded-2xl border border-error/20 bg-error/5 px-6 py-12 text-center">
                <.icon name="hero-exclamation-triangle" class="mx-auto mb-4 size-12 text-error" />
                <h3 class="text-lg font-semibold text-base-content">Registration not found</h3>
                <p class="mx-auto mt-2 max-w-md text-sm text-base-content/65">
                  We couldn’t find a registration with that tracking number. Double-check the code and try again.
                </p>
                <ul class="mx-auto mt-6 max-w-sm space-y-2 text-left text-xs text-base-content/60">
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Use the full tracking number from your submission confirmation
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Format looks like <span class="font-mono">REG-1234567890-abc123</span>
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Avoid extra spaces before or after the code
                  </li>
                </ul>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
