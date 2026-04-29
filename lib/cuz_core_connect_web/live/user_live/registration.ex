defmodule CuzCoreConnectWeb.UserLive.Registration do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash} current_scope={@current_scope}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>

      <div class="flex items-center justify-center relative overflow-hidden">
        <div class="max-w-6xl w-full grid grid-cols-1 lg:grid-cols-2 gap-12 relative py-10">
          <div class="mx-auto max-w-sm lg:flex flex-col justify-center space-y-8">
            <div class="text-center">
              <.header>
                Register for an account
                <:subtitle>
                  Already registered?
                  <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                    Log in
                  </.link>
                  to your account now.
                </:subtitle>
              </.header>
            </div>

            <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
              <.input
                field={@form[:username]}
                label="Full Names"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
              />

              <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
                Create an account
              </.button>
            </.form>
          </div>

          <div class="border-l border-primary/75 pl-10 hidden lg:flex flex-col justify-center space-y-8">
            <div>
              <h1 class="text-4xl text-primary font-bold mb-3">
                Your campus, CONNECTED.
              </h1>
              <p class="text-lg text-base-content/50">
                Cuz - Core Connect brings every part of university life into one place —
                from registration and results to fees and faculty.
              </p>
            </div>
            <div class="space-y-6">
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-academic-cap" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Course Registration</h3>
                  <p class="text-sm text-base-content/60">
                    Browse and enrol in courses, build your timetable, and stay on top of your academic journey — all in a few clicks.
                  </p>
                </div>
              </div>
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-building-office-2" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Department Connect</h3>
                  <p class="text-sm text-base-content/60">
                    Reach your lecturers, faculties, and admin offices directly — no more back-and-forth across campus.
                  </p>
                </div>
              </div>
              <%!-- <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-document-check" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Results & Records</h3>
                  <p class="text-sm text-base-content/60">
                    View your grades, download transcripts, and track your academic standing whenever you need them.
                  </p>
                </div>
              </div> --%>
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-credit-card" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Fee Payments</h3>
                  <p class="text-sm text-base-content/60">
                    Pay tuition and campus fees securely online, anytime — skip the queues and the paperwork.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <:footer>
        <CuzCoreConnectWeb.Navigations.Unauth.footer />
      </:footer>
    </Layouts.unauth>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok,
     socket
     |> redirect(to: CuzCoreConnectWeb.Plugs.UserAuth.signed_in_path(socket))
     |> assign(show_mobile_menu: false)}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok,
     socket
     |> assign_form(changeset)
     |> assign(show_mobile_menu: false), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
