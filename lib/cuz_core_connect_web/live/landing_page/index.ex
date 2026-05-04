defmodule CuzCoreConnectWeb.LandingPageLive do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(show_mobile_menu: false)
     |> assign(contact_form: %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>

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
                <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-2" />
                Track Registration
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

        <section class="px-6 lg:px-20 py-16 bg-base-200">
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

        <section id="developers" class="px-6 lg:px-20 py-20">
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
            <.link navigate={~p"/student/registration"} class="btn bg-base-300 hover:bg-base-100 w-full sm:w-auto">
              Get Started
            </.link>
          </div>
        </section>

        <section id="help-center" class="mt-6 px-4 lg:px-20 py-16 text-center">
          <div class="max-w-5xl mx-auto relative">
            <div class="text-center mb-4 animate-fadeInUp">
              <h2 class="text-2xl md:text-3xl lg:text-4xl font-bold mb-4">
                Get in Touch
              </h2>
              <p class="text-base md:text-xl">
                Have questions? Our team is ready to help you get started with Cavendish University Zambia - CUZ Core Connect.
              </p>
            </div>

            <div class="glass rounded-2xl shadow-xl p-6 md:p-12 animate-fadeInUp delay-200 border border-gray-200">
              <%!-- Contact Info Cards --%>
              <div class="grid md:grid-cols-3 gap-4 md:gap-6 mb-8">
                <div class="flex flex-col items-center text-center p-2 md:p-4 rounded-md">
                  <div class="w-10 h-10 md:w-12 md:h-12 rounded-full gradient-primary flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                    <.icon name="hero-envelope" class="w-5 h-5 md:w-6 md:h-6" />
                  </div>
                  <h3 class="font-semibold text-sm md:text-base mb-1">Email Us</h3>
                  <p class="text-xs md:text-sm">support@cuz.coreconnect.edu</p>
                </div>

                <div class="flex flex-col items-center text-center p-2 md:p-4 rounded-md">
                  <div
                    class="w-10 h-10 md:w-12 md:h-12 rounded-full gradient-secondary flex items-center justify-center mb-3 group-hover:scale-110 transition-transform"
                    phx-click="boom"
                  >
                    <.icon name="hero-phone" class="w-5 h-5 md:w-6 md:h-6" />
                  </div>
                  <h3 class="font-semibold text-sm md:text-base mb-1">Call Us</h3>
                  <p class="text-xs md:text-sm">+260 211 123 4567</p>
                </div>

                <div class="flex flex-col items-center text-center p-2 md:p-4 rounded-md">
                  <div class="w-10 h-10 md:w-12 md:h-12 rounded-full gradient-primary flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                    <.icon name="hero-map-pin" class="w-5 h-5 md:w-6 md:h-6" />
                  </div>
                  <h3 class="font-semibold text-sm md:text-base mb-1">Visit Us</h3>
                  <p class="text-xs md:text-sm">Lusaka, Zambia</p>
                </div>
              </div>

              <div class="max-w-2xl mx-auto">
                <.form :let={c} for={@contact_form} phx-submit="submit_contact" class="space-y-4">
                  <div class="grid md:grid-cols-2 gap-4">
                    <div>
                      <.input
                        type="text"
                        field={c[:name]}
                        placeholder="Your Name"
                        class="w-full px-3 py-2 md:px-4 md:py-3 border border-gray-300 rounded-lg focus:border-[#f0421f] focus:ring-2 focus:ring-[#f0421f] focus:ring-opacity-20 transition-all outline-none text-sm md:text-base"
                        required
                      />
                    </div>
                    <div>
                      <.input
                        type="email"
                        field={c[:email]}
                        placeholder="Your Email"
                        class="w-full px-3 py-2 md:px-4 md:py-3 border border-gray-300 rounded-lg focus:border-[#f0421f] focus:ring-2 focus:ring-[#f0421f] focus:ring-opacity-20 transition-all outline-none text-sm md:text-base"
                        required
                      />
                    </div>
                  </div>

                  <div>
                    <.input
                      type="text"
                      field={c[:subject]}
                      placeholder="Subject"
                      class="w-full px-3 py-2 md:px-4 md:py-3 border border-gray-300 rounded-lg focus:border-[#f0421f] focus:ring-2 focus:ring-[#f0421f] focus:ring-opacity-20 transition-all outline-none text-sm md:text-base"
                      required
                    />
                  </div>

                  <div>
                    <.input
                      type="textarea"
                      field={c[:message]}
                      placeholder="Your Message"
                      rows="4"
                      class="w-full px-3 py-2 md:px-4 md:py-3 border border-gray-300 rounded-lg focus:border-[#f0421f] focus:ring-2 focus:ring-[#f0421f] focus:ring-opacity-20 transition-all outline-none resize-none text-sm md:text-base"
                      required
                    />
                  </div>

                  <.button
                    type="submit"
                    phx-disable-with="Sending..."
                    class="w-full gradient-primary px-4 py-3 md:px-6 md:py-4 rounded-lg font-medium bg-base-200 hover:bg-base-300 transition-all duration-300 flex items-center justify-center text-sm md:text-base"
                  >
                    <span class="flex items-center">
                      Send Message <.icon name="hero-paper-airplane" class="w-4 h-4 md:w-5 md:h-5 ml-2" />
                    </span>
                  </.button>
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

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end
end
