defmodule CuzCoreConnectWeb.LandingPageLive do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Communications

  @impl true
  def mount(_params, _session, socket) do
    contact_form =
      Communications.change_contact_message()
      |> to_form(as: :contact)

    {:ok,
     socket
     |> assign(show_mobile_menu: false)
     |> assign(contact_form: contact_form)
     |> assign(announcements: Communications.list_published_announcements())
     |> assign(landing_messages: Communications.list_landing_messages())}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  def handle_event("submit_contact", %{"contact" => params}, socket) do
    case Communications.create_contact_message(params) do
      {:ok, _message} ->
        contact_form =
          Communications.change_contact_message()
          |> to_form(as: :contact)

        {:noreply,
         socket
         |> put_flash(:info, "Thanks! Your message was sent.")
         |> assign(:contact_form, contact_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, :contact_form, to_form(changeset, as: :contact))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>

      <section
        :if={@announcements != []}
        id="announcements-marquee"
        class="border-y border-primary/20 bg-primary text-primary-content"
      >
        <div class="flex items-stretch">
          <div class="flex shrink-0 items-center gap-2 bg-primary-content/15 px-4 py-2.5 text-xs font-bold uppercase tracking-wider">
            <.icon name="hero-megaphone" class="size-4" /> Announcements
          </div>
          <div class="announcement-marquee relative min-w-0 flex-1 overflow-hidden py-2.5">
            <div class="announcement-marquee-track flex w-max gap-10 whitespace-nowrap px-6 text-sm">
              <%= for item <- @announcements ++ @announcements do %>
                <span class="inline-flex items-center gap-2">
                  <span class="font-semibold">{item.title}</span>
                  <span class="opacity-80">— {item.body}</span>
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-20">
        <div class="w-full">
          <h1 class="text-3xl sm:text-4xl lg:text-6xl font-bold leading-tight">
            Transform University Registration with
            <span class="text-primary">Workflow Automation</span>
          </h1>

          <p class="mt-6 text-sm sm:text-base lg:text-lg text-base-content/70 max-w-2xl">
            A secure, workflow-driven academic registration system designed to eliminate delays,
            improve transparency, and streamline multi-departmental approvals across universities.
          </p>

          <div class="mt-8 flex flex-col sm:flex-row gap-4">
            <.link navigate={~p"/student/registration"} class="btn btn-primary w-full sm:w-auto">
              Start your Registration Process
            </.link>
            <.link navigate={~p"/registration/tracking"} class="btn btn-outline w-full sm:w-auto">
              <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-2" /> Track Registration
            </.link>
            <.link navigate={~p"/learn-more"} class="btn btn-outline w-full sm:w-auto">
              Learn More
            </.link>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16 bg-base-200">
        <h2 class="text-2xl md:text-3xl font-semibold mb-10">The Problem</h2>

        <div class="grid md:grid-cols-3 gap-6">
          <div class="p-4 sm:p-6 bg-error/5 rounded-lg border border-error/20">
            <.icon name="hero-clock" class="w-6 h-6 text-error mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-error">Delayed Approvals</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Manual coordination between departments causes long processing times.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-warning/5 rounded-lg border border-warning/20">
            <.icon name="hero-eye-slash" class="w-6 h-6 text-warning mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-warning">Lack of Transparency</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              No clear visibility into where a registration request is in the process.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-info/5 rounded-lg border border-info/20">
            <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-info mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-info">Data Inconsistency</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Fragmented tools like forms lead to errors and duplicated verification.
            </p>
          </div>
        </div>
      </section>

      <section id="about" class="px-6 lg:px-20 py-20">
        <h2 class="text-2xl md:text-3xl font-semibold mb-6">Our Solution</h2>

        <p class="max-w-3xl text-sm md:text-base text-base-content/70 mb-10">
          UniFlow introduces a structured, role-based workflow engine that automates
          registration processes, enforces accountability, and ensures secure coordination
          between all academic departments.
        </p>

        <div class="grid md:grid-cols-3 gap-6">
          <div class="p-4 sm:p-6 bg-primary/5 rounded-lg border border-primary/20 hover:bg-primary/10 transition-colors">
            <.icon name="hero-cog-6-tooth" class="w-6 h-6 text-primary mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-primary">Workflow Engine</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Automates transitions from submission to approval using defined states.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-success/5 rounded-lg border border-success/20 hover:bg-success/10 transition-colors">
            <.icon name="hero-shield-check" class="w-6 h-6 text-success mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-success">Role-Based Access Control</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Ensures each department only accesses what they are authorized to see.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-secondary/5 rounded-lg border border-secondary/20 hover:bg-secondary/10 transition-colors">
            <.icon name="hero-document-text" class="w-6 h-6 text-secondary mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-secondary">Audit Logging</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Tracks every action with timestamps for accountability and traceability.
            </p>
          </div>
        </div>
      </section>

      <section id="registration-messages" class="px-6 lg:px-20 py-16 bg-base-200">
        <div class="mb-8 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 class="text-2xl md:text-3xl font-semibold">Recent Registrations</h2>
            <p class="mt-2 text-sm text-base-content/60">
              Live notices when students submit registrations through CUZ Core Connect.
            </p>
          </div>
        </div>

        <%= if @landing_messages == [] do %>
          <div class="rounded-box border border-dashed border-base-300 bg-base-100 p-10 text-center">
            <.icon name="hero-chat-bubble-left-right" class="mx-auto mb-3 size-10 text-base-content/30" />
            <p class="font-medium text-base-content/70">No registration messages yet</p>
            <p class="mt-1 text-sm text-base-content/50">
              New student submissions will appear here.
            </p>
          </div>
        <% else %>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <article
              :for={msg <- @landing_messages}
              id={"landing-message-#{msg.id}"}
              class="rounded-box border border-base-300 bg-base-100 p-5 shadow-sm transition hover:border-primary/30"
            >
              <div class="mb-3 flex items-start justify-between gap-3">
                <div class="flex items-center gap-2">
                  <div class="rounded-full bg-primary/10 p-2">
                    <.icon name="hero-user" class="size-4 text-primary" />
                  </div>
                  <div>
                    <p class="font-semibold text-base-content">{msg.name}</p>
                    <p class="text-xs text-base-content/50">{msg.subject}</p>
                  </div>
                </div>
                <span class="badge badge-sm badge-outline">
                  {Calendar.strftime(msg.inserted_at, "%d %b")}
                </span>
              </div>
              <p class="text-sm leading-relaxed text-base-content/70">{msg.body}</p>
            </article>
          </div>
        <% end %>
      </section>

      <section class="px-6 lg:px-20 py-16">
        <h2 class="text-2xl md:text-3xl font-semibold mb-10">Approval Workflow</h2>

        <div class="flex flex-wrap gap-2 sm:gap-4 text-xs sm:text-sm font-medium">
          <span class="badge badge-outline">Draft</span>
          <span class="badge badge-outline">Submitted</span>
          <span class="badge badge-outline">Finance</span>
          <span class="badge badge-outline">HOD</span>
          <span class="badge badge-outline">Academics</span>
          <span class="badge badge-success">Approved</span>
        </div>

        <p class="mt-6 text-sm md:text-base text-base-content/70 max-w-2xl">
          Each transition is role-restricted, timestamped, and securely logged,
          ensuring full transparency and accountability across departments.
        </p>
      </section>

      <section id="developers" class="px-6 lg:px-20 py-20 bg-base-200">
        <h2 class="text-2xl md:text-3xl font-semibold mb-10">Key Features</h2>

        <div class="grid md:grid-cols-2 gap-6">
          <div class="p-4 sm:p-6 bg-info/5 rounded-lg border border-info/20 hover:bg-info/10 transition-colors">
            <.icon name="hero-rocket-launch" class="w-6 h-6 text-info mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-info">Performance Optimization</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Reduced approval latency and faster processing times through automation.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-warning/5 rounded-lg border border-warning/20 hover:bg-warning/10 transition-colors">
            <.icon name="hero-users" class="w-6 h-6 text-warning mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-warning">Concurrent User Handling</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Designed to perform under high user load conditions.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-success/5 rounded-lg border border-success/20 hover:bg-success/10 transition-colors">
            <.icon name="hero-lock-closed" class="w-6 h-6 text-success mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-success">Secure Authentication</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Protects sensitive student data with strong access control mechanisms.
            </p>
          </div>

          <div class="p-4 sm:p-6 bg-primary/5 rounded-lg border border-primary/20 hover:bg-primary/10 transition-colors">
            <.icon name="hero-chart-pie" class="w-6 h-6 text-primary mb-3" />
            <h3 class="font-semibold text-base sm:text-lg text-primary">Administrative Dashboard</h3>
            <p class="text-xs sm:text-sm mt-2 text-base-content/70">
              Provides insights into workflow performance and bottlenecks.
            </p>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-20 bg-primary text-primary-content text-center">
        <h2 class="text-2xl md:text-3xl font-semibold">
          Ready to Modernize Academic Registration?
        </h2>

        <p class="mt-4 max-w-xl mx-auto text-sm md:text-base text-primary-content/80">
          Experience a smarter, faster, and more transparent registration system built for modern universities.
        </p>

        <div class="mt-6">
          <.link
            navigate={~p"/student/registration"}
            class="btn bg-base-300 hover:bg-base-100 w-full sm:w-auto"
          >
            Get Started
          </.link>
        </div>
      </section>

      <section id="help-center" class="mt-6 px-4 lg:px-20 py-16 text-center">
        <div class="max-w-5xl mx-auto relative">
          <div class="text-center mb-4">
            <h2 class="text-2xl md:text-3xl lg:text-4xl font-bold mb-4">
              Get in Touch
            </h2>
            <p class="text-base md:text-xl text-base-content/70">
              Have questions? Send a message — it will appear in the admin Messages inbox.
            </p>
          </div>

          <div class="rounded-2xl border border-base-300 bg-base-100 p-6 md:p-12 shadow-sm">
            <div class="grid md:grid-cols-3 gap-4 md:gap-6 mb-8">
              <div class="flex flex-col items-center text-center p-2 md:p-4">
                <.icon name="hero-envelope" class="mb-3 size-6 text-primary" />
                <h3 class="font-semibold text-sm md:text-base mb-1">Email Us</h3>
                <p class="text-xs md:text-sm text-base-content/60">support@cuz.coreconnect.edu</p>
              </div>
              <div class="flex flex-col items-center text-center p-2 md:p-4">
                <.icon name="hero-phone" class="mb-3 size-6 text-primary" />
                <h3 class="font-semibold text-sm md:text-base mb-1">Call Us</h3>
                <p class="text-xs md:text-sm text-base-content/60">+260 211 123 4567</p>
              </div>
              <div class="flex flex-col items-center text-center p-2 md:p-4">
                <.icon name="hero-map-pin" class="mb-3 size-6 text-primary" />
                <h3 class="font-semibold text-sm md:text-base mb-1">Visit Us</h3>
                <p class="text-xs md:text-sm text-base-content/60">Lusaka, Zambia</p>
              </div>
            </div>

            <div class="max-w-2xl mx-auto text-left">
              <.form for={@contact_form} id="landing-contact-form" phx-submit="submit_contact" class="space-y-4">
                <div class="grid md:grid-cols-2 gap-4">
                  <.input field={@contact_form[:name]} type="text" label="Your Name" required />
                  <.input field={@contact_form[:email]} type="email" label="Your Email" required />
                </div>
                <.input field={@contact_form[:subject]} type="text" label="Subject" required />
                <.input field={@contact_form[:body]} type="textarea" label="Your Message" required />
                <button
                  type="submit"
                  phx-disable-with="Sending..."
                  class="btn btn-primary w-full gap-2"
                >
                  Send Message
                  <.icon name="hero-paper-airplane" class="size-4" />
                </button>
              </.form>
            </div>
          </div>
        </div>
      </section>
      <:footer>
        <CuzCoreConnectWeb.Navigations.Unauth.footer />
      </:footer>
    </Layouts.unauth>
    """
  end
end
