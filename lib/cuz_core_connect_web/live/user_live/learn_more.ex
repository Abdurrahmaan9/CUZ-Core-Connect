defmodule CuzCoreConnectWeb.UserLive.LearnMore do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_mobile_menu: false)}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>

      <section class="px-6 lg:px-20 py-20">
        <div class="w-full max-w-3xl">
          <p class="text-sm font-semibold uppercase tracking-wider text-primary mb-3">
            How it works
          </p>
          <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold leading-tight text-base-content">
            Course registration with <span class="text-primary">multi-stage approvals</span>
          </h1>
          <p class="mt-6 text-sm sm:text-base lg:text-lg text-base-content/70">
            CUZ Core Connect is the university registration system for submitting course
            registrations, verifying payments, and moving each request through Finance,
            Academics, HOD, and Retention — with a tracking number at every stage.
          </p>
          <div class="mt-8 flex flex-col sm:flex-row gap-4">
            <.link navigate={~p"/student/registration"} class="btn btn-primary w-full sm:w-auto">
              Start Registration
            </.link>
            <.link navigate={~p"/registration/tracking"} class="btn btn-outline w-full sm:w-auto">
              <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-2" /> Track Registration
            </.link>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16 bg-base-200">
        <h2 class="text-2xl md:text-3xl font-semibold mb-4">Student submission</h2>
        <p class="max-w-2xl text-sm md:text-base text-base-content/70 mb-10">
          Registrations are completed in a six-step wizard. You do not need an account to
          start — submit the form, then use your tracking number to follow progress.
        </p>

        <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              1
            </div>
            <h3 class="font-semibold text-base-content">Personal info</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Enter your student details, contact information, and identifiers used on the registration.
            </p>
          </div>

          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              2
            </div>
            <h3 class="font-semibold text-base-content">Programme</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Select the academic programme you are registering under.
            </p>
          </div>

          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              3
            </div>
            <h3 class="font-semibold text-base-content">Semester</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Choose the academic year, semester, and intake for this registration period.
            </p>
          </div>

          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              4
            </div>
            <h3 class="font-semibold text-base-content">Courses</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Add the courses for your programme and review credit hours before continuing.
            </p>
          </div>

          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              5
            </div>
            <h3 class="font-semibold text-base-content">Payment receipts</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Upload proof of payment (JPG, PNG, WebP, or PDF — up to 3 files, 5 MB each).
            </p>
          </div>

          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <div class="mb-3 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-content">
              6
            </div>
            <h3 class="font-semibold text-base-content">Review & submit</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Confirm every detail, submit, and save the tracking number shown on success.
            </p>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16">
        <h2 class="text-2xl md:text-3xl font-semibold mb-4">Approval workflow</h2>
        <p class="max-w-2xl text-sm md:text-base text-base-content/70 mb-8">
          After submission, the default workflow moves the registration through four
          departmental stages. Each stage can approve or reject; you are notified by email
          when a stage decision is made.
        </p>

        <div class="flex flex-wrap items-center gap-2 sm:gap-3 text-xs sm:text-sm font-medium mb-10">
          <span class="badge badge-outline">Submitted</span>
          <.icon name="hero-arrow-right" class="hidden sm:block size-4 text-base-content/40" />
          <span class="badge badge-primary badge-outline">Finance</span>
          <.icon name="hero-arrow-right" class="hidden sm:block size-4 text-base-content/40" />
          <span class="badge badge-outline">Academics</span>
          <.icon name="hero-arrow-right" class="hidden sm:block size-4 text-base-content/40" />
          <span class="badge badge-outline">HOD</span>
          <.icon name="hero-arrow-right" class="hidden sm:block size-4 text-base-content/40" />
          <span class="badge badge-outline">Retention</span>
          <.icon name="hero-arrow-right" class="hidden sm:block size-4 text-base-content/40" />
          <span class="badge badge-success">Approved</span>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <div class="p-5 bg-warning/5 rounded-lg border border-warning/20">
            <.icon name="hero-banknotes" class="mb-3 size-6 text-warning" />
            <h3 class="font-semibold text-warning">1. Finance</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Verifies payment receipts attached to your registration.
            </p>
          </div>
          <div class="p-5 bg-info/5 rounded-lg border border-info/20">
            <.icon name="hero-academic-cap" class="mb-3 size-6 text-info" />
            <h3 class="font-semibold text-info">2. Academics</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Reviews programme and course selections for academic validity.
            </p>
          </div>
          <div class="p-5 bg-secondary/5 rounded-lg border border-secondary/20">
            <.icon name="hero-building-office-2" class="mb-3 size-6 text-secondary" />
            <h3 class="font-semibold text-secondary">3. HOD</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Head of Department approval after Finance and Academics have approved.
            </p>
          </div>
          <div class="p-5 bg-success/5 rounded-lg border border-success/20">
            <.icon name="hero-shield-check" class="mb-3 size-6 text-success" />
            <h3 class="font-semibold text-success">4. Retention</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Final clearance. Once approved here, the registration is fully complete.
            </p>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16 bg-base-200">
        <h2 class="text-2xl md:text-3xl font-semibold mb-4">Track your registration</h2>
        <p class="max-w-2xl text-sm md:text-base text-base-content/70 mb-8">
          Every submission receives a unique tracking number. Use it on the tracking page
          to see stage statuses (payment, academics, HOD, retention) without signing in.
        </p>
        <div class="grid gap-4 sm:grid-cols-2 max-w-3xl">
          <div class="flex gap-3 p-5 bg-base-100 rounded-lg border border-base-300">
            <.icon name="hero-hashtag" class="mt-0.5 size-5 shrink-0 text-primary" />
            <div>
              <h3 class="font-semibold text-base-content">Save your tracking number</h3>
              <p class="mt-1 text-sm text-base-content/70">
                It is shown immediately after a successful submit — copy it before you leave.
              </p>
            </div>
          </div>
          <div class="flex gap-3 p-5 bg-base-100 rounded-lg border border-base-300">
            <.icon name="hero-magnifying-glass" class="mt-0.5 size-5 shrink-0 text-primary" />
            <div>
              <h3 class="font-semibold text-base-content">Check status anytime</h3>
              <p class="mt-1 text-sm text-base-content/70">
                Open Track Registration and enter the number to view live approval progress.
              </p>
            </div>
          </div>
        </div>
        <div class="mt-8">
          <.link navigate={~p"/registration/tracking"} class="btn btn-outline">
            Go to tracking <.icon name="hero-arrow-right" class="ml-1 size-4" />
          </.link>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16">
        <h2 class="text-2xl md:text-3xl font-semibold mb-4">Who uses the system</h2>
        <p class="max-w-2xl text-sm md:text-base text-base-content/70 mb-10">
          Access is role-based. Staff sign in to dedicated dashboards; students can register
          publicly and optionally create an account for login and personal settings.
        </p>

        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div class="p-5 bg-primary/5 rounded-lg border border-primary/20">
            <.icon name="hero-user" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold text-primary">Students</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Submit registrations, upload receipts, and track approval status.
            </p>
          </div>
          <div class="p-5 bg-warning/5 rounded-lg border border-warning/20">
            <.icon name="hero-banknotes" class="mb-3 size-6 text-warning" />
            <h3 class="font-semibold text-warning">Finance</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Verify payments and approve or reject receipt documentation.
            </p>
          </div>
          <div class="p-5 bg-info/5 rounded-lg border border-info/20">
            <.icon name="hero-academic-cap" class="mb-3 size-6 text-info" />
            <h3 class="font-semibold text-info">Academics</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Review course and programme choices from an academic perspective.
            </p>
          </div>
          <div class="p-5 bg-secondary/5 rounded-lg border border-secondary/20">
            <.icon name="hero-building-office-2" class="mb-3 size-6 text-secondary" />
            <h3 class="font-semibold text-secondary">HOD</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Provide department-level approval after earlier stages clear.
            </p>
          </div>
          <div class="p-5 bg-success/5 rounded-lg border border-success/20">
            <.icon name="hero-shield-check" class="mb-3 size-6 text-success" />
            <h3 class="font-semibold text-success">Retention</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Issue final approval before a registration is marked complete.
            </p>
          </div>
          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <.icon name="hero-cog-6-tooth" class="mb-3 size-6 text-base-content" />
            <h3 class="font-semibold text-base-content">Administrators</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Manage users, programmes, courses, announcements, and the active approval workflow.
            </p>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-16 bg-base-200">
        <h2 class="text-2xl md:text-3xl font-semibold mb-4">Accounts & sign-in</h2>
        <div class="grid gap-4 md:grid-cols-2 max-w-4xl">
          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <.icon name="hero-envelope" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold text-base-content">Create an account</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Sign up with a username and email. You receive a magic link to confirm and
              log in — no password is set at registration.
            </p>
            <.link navigate={~p"/users/register"} class="btn btn-outline btn-sm mt-4">
              Sign up
            </.link>
          </div>
          <div class="p-5 bg-base-100 rounded-lg border border-base-300">
            <.icon name="hero-lock-closed" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold text-base-content">Log in</h3>
            <p class="mt-2 text-sm text-base-content/70">
              Use email and password if one was issued for your account, or request a
              magic-link login by email. Staff accounts are typically created by an admin.
            </p>
            <.link navigate={~p"/users/log-in"} class="btn btn-outline btn-sm mt-4">
              Log in
            </.link>
          </div>
        </div>
      </section>

      <section class="px-6 lg:px-20 py-20 bg-primary text-primary-content text-center">
        <h2 class="text-2xl md:text-3xl font-semibold">Ready to register?</h2>
        <p class="mt-4 mx-auto max-w-xl text-sm md:text-base text-primary-content/80">
          Start the six-step registration, keep your tracking number, and follow approvals
          as Finance, Academics, HOD, and Retention complete their reviews.
        </p>
        <div class="mt-6 flex flex-col sm:flex-row gap-3 justify-center">
          <.link
            navigate={~p"/student/registration"}
            class="btn bg-base-300 hover:bg-base-100 w-full sm:w-auto"
          >
            Start Registration
          </.link>
          <.link navigate={~p"/"} class="btn btn-ghost border-primary-content/30 w-full sm:w-auto">
            Back to Home
          </.link>
        </div>
      </section>

      <section class="mt-6 px-4 lg:px-20 py-16 text-center">
        <h2 class="text-2xl md:text-3xl font-bold mb-4">Need help?</h2>
        <p class="mb-8 text-base text-base-content/70">
          Reach the CUZ Core Connect support team or visit us on campus.
        </p>
        <div class="mx-auto grid max-w-4xl gap-4 md:grid-cols-3">
          <div class="flex flex-col items-center p-4">
            <.icon name="hero-envelope" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold mb-1">Email</h3>
            <a
              href="mailto:support@cuz.coreconnect.edu"
              class="text-sm text-primary hover:underline"
            >
              support@cuz.coreconnect.edu
            </a>
          </div>
          <div class="flex flex-col items-center p-4">
            <.icon name="hero-phone" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold mb-1">Phone</h3>
            <p class="text-sm text-base-content/60">+260 211 123 4567</p>
          </div>
          <div class="flex flex-col items-center p-4">
            <.icon name="hero-map-pin" class="mb-3 size-6 text-primary" />
            <h3 class="font-semibold mb-1">Location</h3>
            <p class="text-sm text-base-content/60">Lusaka, Zambia</p>
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
