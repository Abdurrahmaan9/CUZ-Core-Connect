defmodule CuzCoreConnectWeb.GetStartedLive do
  use CuzCoreConnectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:count, 0)
     |> assign(:subtitle, "This page is powered by Phoenix LiveView, updating instantly without a page reload.")}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto w-full rounded-[2rem] border border-base-200 bg-base-100/80 p-8 shadow-xl shadow-base-200/40">
        <div class="space-y-8">

          <%!-- Registration Instructions --%>
          <div class="rounded-3xl bg-gradient-to-r from-primary/10 to-primary/5 p-8 border border-primary/20">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center">
                <.icon name="hero-academic-cap" class="w-6 h-6" />
              </div>
              <div>
                <h1 class="text-3xl font-bold text-base-content">Online Registration Guide</h1>
                <p class="text-base-content/70 mt-1">Complete your course registration in 4 simple steps</p>
              </div>
            </div>

            <div class="grid gap-6 mt-8">
              <%!-- Step 1 --%>
              <div class="flex gap-4 p-4 bg-base-100 rounded-xl border border-base-200">
                <div class="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center text-sm font-semibold flex-shrink-0">1</div>
                <div class="flex-1">
                  <h3 class="font-semibold text-base-content mb-1">Choose Your Program</h3>
                  <p class="text-sm text-base-content/70">Select your academic program from the available options. This determines which courses you can register for.</p>
                  <div class="mt-3">
                    <.link navigate="/registration" class="btn btn-primary btn-sm">
                      Start Registration
                      <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
                    </.link>
                  </div>
                </div>
              </div>

              <%!-- Step 2 --%>
              <div class="flex gap-4 p-4 bg-base-100 rounded-xl border border-base-200">
                <div class="w-8 h-8 rounded-full bg-base-200 text-base-content flex items-center justify-center text-sm font-semibold flex-shrink-0">2</div>
                <div class="flex-1">
                  <h3 class="font-semibold text-base-content mb-1">Select Academic Period</h3>
                  <p class="text-sm text-base-content/70">Enter your academic year (e.g., 2025/2026) and choose the semester you're registering for.</p>
                </div>
              </div>

              <%!-- Step 3 --%>
              <div class="flex gap-4 p-4 bg-base-100 rounded-xl border border-base-200">
                <div class="w-8 h-8 rounded-full bg-base-200 text-base-content flex items-center justify-center text-sm font-semibold flex-shrink-0">3</div>
                <div class="flex-1">
                  <h3 class="font-semibold text-base-content mb-1">Add Your Courses</h3>
                  <p class="text-sm text-base-content/70">Browse available courses and add them to your registration. Use the search to find specific courses and monitor your total credit hours.</p>
                </div>
              </div>

              <%!-- Step 4 --%>
              <div class="flex gap-4 p-4 bg-base-100 rounded-xl border border-base-200">
                <div class="w-8 h-8 rounded-full bg-base-200 text-base-content flex items-center justify-center text-sm font-semibold flex-shrink-0">4</div>
                <div class="flex-1">
                  <h3 class="font-semibold text-base-content mb-1">Review & Submit</h3>
                  <p class="text-sm text-base-content/70">Carefully review all your registration details before submitting. Once submitted, you may need to contact academic support for changes.</p>
                </div>
              </div>
            </div>
          </div>
          <%!-- END Registration Instructions --%>

          <%!-- Help Section --%>
          <div class="rounded-3xl bg-base-200 p-6">
            <div class="flex items-start gap-3">
              <div class="flex-1">
                <h2 class="text-xl font-semibold text-base-content mb-3">Need Help?</h2>
                <div class="grid gap-4 sm:grid-cols-2">
                  <div class="p-4 bg-base-100 rounded-lg border border-base-200">
                    <div class="flex items-center gap-2 mb-2">
                      <.icon name="hero-lifebuoy" class="w-5 h-5 text-primary" />
                      <h3 class="font-medium text-base-content">Academic Support</h3>
                    </div>
                    <p class="text-sm text-base-content/70">Contact our academic advisors for program guidance and registration assistance.</p>
                    <div class="mt-2">
                      <a href="mailto:support@university.edu" class="text-sm text-primary hover:underline">support@university.edu</a>
                    </div>
                  </div>

                  <div class="p-4 bg-base-100 rounded-lg border border-base-200">
                    <div class="flex items-center gap-2 mb-2">
                      <.icon name="hero-clock" class="w-5 h-5 text-primary" />
                      <h3 class="font-medium text-base-content">Registration Hours</h3>
                    </div>
                    <p class="text-sm text-base-content/70">Monday - Friday: 8:00 AM - 5:00 PM</p>
                    <p class="text-sm text-base-content/70">Saturday: 9:00 AM - 1:00 PM</p>
                  </div>
                </div>
              </div>

              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn btn-ghost btn-sm btn-circle">
                  <.icon name="hero-question-mark-circle" class="w-5 h-5" />
                </label>
                <div tabindex="0" class="dropdown-content menu p-4 shadow bg-base-100 rounded-box w-80 z-50">
                  <div class="text-sm">
                    <h3 class="font-semibold text-base-content mb-2">Registration Tips</h3>
                    <ul class="space-y-2 text-base-content/60">
                      <li>• Have your student ID ready</li>
                      <li>• Know your academic program</li>
                      <li>• Check course prerequisites</li>
                      <li>• Review credit requirements</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <%!-- END Help Section --%>

          <%!-- Quick Actions --%>
          <div class="flex flex-wrap gap-4 justify-center">
            <.link navigate="/Student/registration" class="btn btn-primary btn-lg">
              <.icon name="hero-rocket-launch" class="w-5 h-5 mr-2" />
              Start Registration Now
            </.link>
            <.link navigate="/" class="btn btn-outline btn-lg">
              <.icon name="hero-home" class="w-5 h-5 mr-2" />
              Back to Home
            </.link>
          </div>
          <%!-- END Quick Actions --%>

        </div>
      </div>
    </Layouts.app>
    """
  end
end
