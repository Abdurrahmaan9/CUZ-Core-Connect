defmodule CuzCoreConnectWeb.UserLive.Login do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.User
  alias CuzCoreConnect.Accounts.Scope

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
                <p>Log in</p>
                <:subtitle>
                  <%= if @current_scope do %>
                    You need to reauthenticate to perform sensitive actions on your account.
                  <% else %>
                    Don't have an account? <.link
                      navigate={~p"/users/register"}
                      class="font-semibold text-brand hover:underline"
                      phx-no-format
                    >Sign up</.link> for an account now.
                  <% end %>
                </:subtitle>
              </.header>
            </div>

            <div :if={local_mail_adapter?()} class="alert alert-info rounded-sm">
              <.icon name="hero-information-circle" class="size-6 shrink-0" />
              <div>
                <p>You are running the local mail adapter.</p>
                <p>
                  To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
                </p>
              </div>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
            >
              <.input
                readonly={@current_scope && @current_scope.user != nil}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                spellcheck="false"
              />

              <div class="flex items-center justify-between mt-2">
                <.input
                  id="remember-me"
                  field={@form[:remember_me]}
                  label="Remember me"
                  type="checkbox"
                />

                <.button
                  navigate="#"
                  class="fieldset mb-2"
                >
                  <span class="label underline text-orange-600 hover:text-orange-700 transition-colors duration-300">
                    Forgot password?
                  </span>
                </.button>
              </div>
              <.button class="btn btn-primary w-full">
                Log in <span aria-hidden="true">→</span>
              </.button>
            </.form>

            <div class="divider">or</div>

            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
            >
              <.input
                readonly={@current_scope && @current_scope.user != nil}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
              />
              <div class="fieldset mb-2">
                <span class="label">* For invited users who have not set a password.</span><span class="label">* A secure login link will be sent to your email.</span>
              </div>
              <.button class="btn btn-primary w-full">
                Log in with email only <span aria-hidden="true">→</span>
              </.button>
            </.form>
          </div>

          <div class="border-l border-primary/75 pl-10 hidden lg:flex flex-col justify-center space-y-8">
            <div>
              <h1 class="text-4xl text-primary font-bold mb-3">Welcome Back</h1>
              <p class="text-lg text-base-content/50">
                Your all-in-one university core connect portal — manage registration, courses, and campus life in one place.
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
                    Enrol in courses, manage your timetable, and track your academic progress effortlessly.
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
                    Communicate directly with your faculty, departments, and administrative offices.
                  </p>
                </div>
              </div>
              <%!-- <div class="flex items-start space-x-4 hover:translate-x-2 transition-transform duration-300">
                <div class="flex-shrink-0 bg-orange-600 rounded-lg p-2 shadow-md">
                  <.icon name="hero-document-check" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Results & Transcripts</h3>
                  <p>
                    Access your exam results, request official transcripts, and view your academic record.
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
                    Pay tuition and campus fees securely online — no queues, no paperwork.
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
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        case socket.assigns[:current_scope] do
          %Scope{user: %User{} = user} -> user.email
          _ -> nil
        end

    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> assign(form: form, trigger_submit: false)
     |> assign(show_mobile_menu: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:cuz_core_connect, CuzCoreConnect.Mailer)[:adapter] ==
      Swoosh.Adapters.Local
  end
end
