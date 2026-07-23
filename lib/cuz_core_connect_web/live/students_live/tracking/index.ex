defmodule CuzCoreConnectWeb.Student.Tracking.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Registrations

  @impl true
  def mount(_params, _session, socket) do
    authenticated? = match?(%{user: %{id: _}}, socket.assigns[:current_scope])

    registrations =
      if authenticated? do
        Registrations.list_submitted_for_student(socket.assigns.current_scope.user)
      else
        []
      end

    {:ok,
     socket
     |> assign(:page_title, "Track Registration")
     |> assign(:current_page, :student_registration_tracking)
     |> assign(:tracking_number, "")
     |> assign(:status_filter, "all")
     |> assign(:registration, nil)
     |> assign(:registrations, registrations)
     |> assign(:filtered_registrations, registrations)
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

    if logged_in?(socket.assigns) do
      {:noreply,
       socket
       |> assign(:tracking_number, tracking_number)
       |> apply_registration_filters()}
    else
      socket =
        socket
        |> assign(:tracking_number, tracking_number)
        |> assign(:loading, true)
        |> assign(:searched, false)
        |> assign(:registration, nil)

      search_registration(socket, tracking_number)
    end
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, status)
     |> apply_registration_filters()}
  end

  def handle_event("select_registration", %{"id" => id}, socket) do
    registration = Registrations.get_registration!(id)

    if Registrations.owns_registration?(socket.assigns.current_scope.user, registration) do
      {:noreply,
       socket
       |> assign(:registration, registration)
       |> assign(:searched, true)
       |> assign(:tracking_number, registration.tracking_number || "")
       |> then(fn s ->
         if registration.tracking_number do
           push_patch(s, to: ~p"/registration/tracking/#{registration.tracking_number}")
         else
           s
         end
       end)}
    else
      {:noreply, put_flash(socket, :error, "Registration not found.")}
    end
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  def handle_event("clear_search", _params, socket) do
    socket =
      socket
      |> assign(:tracking_number, "")
      |> assign(:status_filter, "all")
      |> assign(:registration, nil)
      |> assign(:searched, false)
      |> assign(:loading, false)

    socket =
      if logged_in?(socket.assigns) do
        apply_registration_filters(socket)
      else
        socket
      end

    {:noreply, push_patch(socket, to: ~p"/registration/tracking")}
  end

  defp apply_registration_filters(socket) do
    query = String.downcase(String.trim(socket.assigns.tracking_number || ""))
    status = socket.assigns.status_filter

    filtered =
      socket.assigns.registrations
      |> Enum.reject(&CuzCoreConnect.Registrations.Registration.draft?/1)
      |> Enum.filter(fn reg ->
        status_ok =
          case status do
            "all" -> true
            s -> overall_status(reg) == String.upcase(s)
          end

        query_ok =
          query == "" or
            String.contains?(String.downcase(reg.tracking_number || ""), query) or
            String.contains?(String.downcase(reg.student_names || ""), query)

        status_ok and query_ok
      end)

    assign(socket, :filtered_registrations, filtered)
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
        if current_path == :show and
             socket.assigns.tracking_number == registration.tracking_number do
          {:noreply, socket}
        else
          {:noreply,
           push_patch(socket, to: ~p"/registration/tracking/#{registration.tracking_number}")}
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
    <%= if @logged_in? do %>
      <.auth_tracking {assigns} />
    <% else %>
      <.public_tracking {assigns} />
    <% end %>
    """
  end

  defp auth_tracking(assigns) do
    ~H"""
    <div class="mx-auto px-4 sm:px-6 py-2 space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-base-content">Track Registrations</h1>
        <p class="text-sm text-base-content/60 mt-1">
          Filter and open your submitted registrations to view approval progress.
        </p>
      </div>

      <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div class="flex flex-wrap gap-2">
          <%= for {label, status} <- [
                {"All", "all"},
                {"Pending", "pending"},
                {"Approved", "approved"},
                {"Rejected", "rejected"}
              ] do %>
            <button
              type="button"
              phx-click="filter_status"
              phx-value-status={status}
              class={[
                "btn btn-sm",
                @status_filter == status && "btn-primary",
                @status_filter != status && "btn-ghost"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>

        <form
          id="tracking-filter-form"
          phx-change="search_tracking"
          phx-submit="search_tracking"
          class="flex gap-2"
        >
          <label class="input input-bordered input-sm flex items-center gap-2 w-full sm:w-72">
            <.icon name="hero-magnifying-glass" class="size-4 opacity-50" />
            <input
              type="text"
              name="tracking_number"
              id="tracking_number"
              value={@tracking_number}
              placeholder="Filter by tracking # or name"
              autocomplete="off"
              class="grow"
            />
          </label>
          <button
            :if={@tracking_number != "" or @status_filter != "all" or @registration}
            type="button"
            phx-click="clear_search"
            class="btn btn-ghost btn-sm"
          >
            Clear
          </button>
        </form>
      </div>

      <div class="overflow-x-auto rounded-box border border-base-300 bg-base-100 shadow-sm">
        <table class="table">
          <thead>
            <tr>
              <th>Tracking #</th>
              <th>Programme</th>
              <th>Submitted</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={reg <- @filtered_registrations}
              id={"tracking-row-#{reg.id}"}
              class={[
                "hover",
                @registration && @registration.id == reg.id && "bg-primary/5"
              ]}
            >
              <td class="font-mono text-sm">{reg.tracking_number || "—"}</td>
              <td class="text-sm">
                {program_detail(reg, "program_name") || "—"}
              </td>
              <td class="text-sm text-base-content/70">
                {Calendar.strftime(reg.registration_date || reg.inserted_at, "%b %d, %Y")}
              </td>
              <td>
                <span class={[
                  "badge badge-sm border",
                  overall_badge_class(overall_status(reg))
                ]}>
                  {overall_label(overall_status(reg))}
                </span>
              </td>
              <td class="text-right">
                <button
                  type="button"
                  phx-click="select_registration"
                  phx-value-id={reg.id}
                  class="btn btn-ghost btn-sm"
                >
                  View
                </button>
              </td>
            </tr>
            <tr :if={@filtered_registrations == []}>
              <td colspan="5" class="py-10 text-center text-base-content/50">
                No registrations match this filter.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@registration} id="tracking-detail" class="space-y-6">
        <.registration_detail {assigns} />
      </div>
    </div>
    """
  end

  defp public_tracking(assigns) do
    ~H"""
    <div class={[
      "mx-auto px-4 sm:px-6",
      "max-w-5xl py-8 sm:py-12"
    ]}>
      <div class="relative overflow-hidden rounded-3xl border border-base-300/70 bg-gradient-to-br from-base-100 via-base-100 to-primary/5 shadow-sm">
        <div class="relative p-5 sm:p-8 lg:p-10 space-y-8">
          <div class="space-y-2">
            <h1 class="text-2xl sm:text-3xl font-bold tracking-tight text-base-content">
              Track Your Registration
            </h1>
            <p class="max-w-xl text-sm sm:text-base text-base-content/65">
              Enter your tracking number to see approval progress across payment, academics, HOD, and retention.
            </p>
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
              class="btn btn-primary"
            >
              Track
            </button>
            <button
              :if={@searched}
              type="button"
              phx-click="clear_search"
              class="btn btn-ghost"
            >
              Clear
            </button>
          </form>

          <div :if={@loading} class="flex flex-col items-center justify-center gap-3 py-14">
            <span class="loading loading-spinner loading-lg text-primary"></span>
            <p class="text-sm text-base-content/60">Looking up your registration…</p>
          </div>

          <div :if={@searched && !@loading} class="space-y-6">
            <%= if @registration do %>
              <.registration_detail {assigns} />
            <% else %>
              <div class="rounded-2xl border border-error/20 bg-error/5 px-6 py-12 text-center">
                <.icon name="hero-exclamation-triangle" class="mx-auto mb-4 size-12 text-error" />
                <h3 class="text-lg font-semibold">Registration not found</h3>
                <p class="mx-auto mt-2 max-w-md text-sm text-base-content/65">
                  We couldn’t find a registration with that tracking number.
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp registration_detail(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class={[
        "flex flex-col gap-4 rounded-2xl border p-4 sm:flex-row sm:items-center sm:justify-between sm:p-5",
        overall_badge_class(@overall)
      ]}>
        <div class="flex items-start gap-3">
          <div class="rounded-xl bg-base-100/70 p-2.5 shadow-sm">
            <.icon name={overall_icon(@overall)} class="size-6" />
          </div>
          <div>
            <p class="text-xs font-medium uppercase tracking-wide opacity-70">Approval Status</p>
            <p class="text-xl font-bold">{overall_label(@overall)}</p>
            <p class="mt-1 font-mono text-xs sm:text-sm opacity-80">
              {@registration.tracking_number}
            </p>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
        <div class="mb-5 flex items-center gap-2">
          <.icon name="hero-arrows-right-left" class="size-5 text-primary" />
          <h2 class="text-base font-semibold sm:text-lg">Approval Pipeline</h2>
        </div>

        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div
            :for={stage <- @stages}
            id={"stage-#{stage.key}"}
            class={[
              "relative rounded-2xl border p-4",
              stage_tone(stage.status)
            ]}
          >
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
          <p class="font-semibold">
            Rejected at {String.capitalize(@registration.rejected_stage || "a stage")}
          </p>
          <p class="mt-1 opacity-90">
            {@registration.rejection_reason || "No reason was provided."}
          </p>
        </div>

        <div
          :if={@overall == "APPROVED"}
          class="mt-5 flex flex-wrap gap-2"
        >
          <.link
            href={~p"/registration/tracking/#{@registration.tracking_number}/proof"}
            target="_blank"
            class="btn btn-success btn-sm"
          >
            View Proof
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
          <h2 class="text-base font-semibold mb-4">Student</h2>
          <dl class="space-y-3 text-sm">
            <div class="flex justify-between gap-4 border-b border-base-200 pb-3">
              <dt class="text-base-content/55">Student number</dt>
              <dd class="font-mono font-semibold">{@registration.student_id}</dd>
            </div>
            <div class="flex justify-between gap-4 border-b border-base-200 pb-3">
              <dt class="text-base-content/55">Name</dt>
              <dd class="font-medium">{@registration.student_names}</dd>
            </div>
            <div class="flex justify-between gap-4">
              <dt class="text-base-content/55">Email</dt>
              <dd class="break-all">{@registration.student_email}</dd>
            </div>
          </dl>
        </div>

        <div class="rounded-2xl border border-base-300 bg-base-100/80 p-4 sm:p-6">
          <h2 class="text-base font-semibold mb-4">Programme</h2>
          <dl class="space-y-3 text-sm">
            <div class="flex justify-between gap-4 border-b border-base-200 pb-3">
              <dt class="text-base-content/55">Programme</dt>
              <dd class="font-medium">{program_detail(@registration, "program_name") || "—"}</dd>
            </div>
            <div class="flex justify-between gap-4 border-b border-base-200 pb-3">
              <dt class="text-base-content/55">Academic year</dt>
              <dd>{program_detail(@registration, "academic_year") || "—"}</dd>
            </div>
            <div class="flex justify-between gap-4">
              <dt class="text-base-content/55">Semester</dt>
              <dd>{program_detail(@registration, "semester") || "—"}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end
end
