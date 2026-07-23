defmodule CuzCoreConnectWeb.UserLive.Registration do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Accounts
  alias CuzCoreConnect.Accounts.StudentEmail

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.unauth flash={@flash} current_scope={@current_scope}>
      <:header>
        <CuzCoreConnectWeb.Navigations.Unauth.header show_mobile_menu={@show_mobile_menu} />
      </:header>

      <div class="flex items-center justify-center relative overflow-hidden">
        <div class="max-w-6xl w-full grid grid-cols-1 lg:grid-cols-2 gap-12 relative py-10">
          <div class="mx-auto max-w-sm w-full lg:flex flex-col justify-center space-y-8">
            <div class="text-center">
              <.header>
                Student portal sign up
                <:subtitle>
                  Create a student account to track course registrations.
                  Already registered?
                  <.link
                    navigate={~p"/users/log-in"}
                    class="font-semibold text-brand hover:underline text-primary"
                  >
                    Log in
                  </.link>
                </:subtitle>
              </.header>
            </div>

            <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
              <.input
                field={@form[:student_number]}
                type="text"
                label="Student number"
                placeholder="e.g. 202512345"
                autocomplete="off"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />

              <div class={["space-y-4", not @student_number_ready && "opacity-50 pointer-events-none"]}>
                <.input
                  field={@form[:first_name]}
                  type="text"
                  label="First name"
                  autocomplete="given-name"
                  required={@student_number_ready}
                />
                <.input
                  field={@form[:last_name]}
                  type="text"
                  label="Last name"
                  autocomplete="family-name"
                  required={@student_number_ready}
                />
                <.input
                  field={@form[:middle_name]}
                  type="text"
                  label="Middle name (optional)"
                  autocomplete="additional-name"
                />

                <div class="space-y-2">
                  <.input
                    field={@form[:email]}
                    type="email"
                    label="Email"
                    placeholder={@email_placeholder}
                    autocomplete="email"
                    spellcheck="false"
                    required={@student_number_ready}
                    readonly={@use_suggested_email and @suggested_email != nil}
                  />
                  <p :if={@suggested_email} class="text-xs text-base-content/60">
                    Suggested institutional email:
                    <span class="font-mono text-base-content/80">{@suggested_email}</span>
                  </p>
                </div>

                <div class="rounded-lg border border-base-300 bg-base-200/40 p-3">
                  <label class="flex items-start gap-3 cursor-pointer">
                    <input type="hidden" name={@form[:use_suggested_email].name} value="false" />
                    <input
                      type="checkbox"
                      id={@form[:use_suggested_email].id}
                      name={@form[:use_suggested_email].name}
                      value="true"
                      checked={@use_suggested_email}
                      class="checkbox checkbox-primary mt-0.5"
                    />
                    <span class="text-sm text-base-content/80">
                      <%= if @suggested_email do %>
                        Use the suggested institutional email above.
                        Uncheck to enter a different email address.
                      <% else %>
                        Use the suggested institutional email once your names are entered.
                        Uncheck to enter a different email address.
                      <% end %>
                    </span>
                  </label>
                </div>
              </div>

              <.button
                phx-disable-with="Creating account..."
                class="btn btn-primary w-full mt-2"
                disabled={not @can_submit}
              >
                Create student account
              </.button>
            </.form>
          </div>

          <div class="border-l border-primary/75 pl-10 hidden lg:flex flex-col justify-center space-y-8">
            <div>
              <h1 class="text-4xl text-primary font-bold mb-3">
                Your campus, CONNECTED.
              </h1>
              <p class="text-lg text-base-content/50">
                Sign up with your student number to receive portal login credentials by email.
                You can then track registration approvals alongside public tracking.
              </p>
            </div>
            <div class="space-y-6">
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-identification" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Student number first</h3>
                  <p class="text-sm text-base-content/60">
                    Enter your institutional student number, then your names.
                  </p>
                </div>
              </div>
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-envelope" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Institutional email</h3>
                  <p class="text-sm text-base-content/60">
                    We suggest
                    <span class="font-mono text-xs">
                      fi + li + student# @{StudentEmail.domain()}
                    </span>
                    — or choose a different address.
                  </p>
                </div>
              </div>
              <div class="flex items-start space-x-4">
                <div class="flex-shrink-0 bg-primary rounded-lg p-2 shadow-md">
                  <.icon name="hero-key" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h3 class="font-medium">Login credentials by email</h3>
                  <p class="text-sm text-base-content/60">
                    A temporary password is emailed so you can sign in to the student portal.
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
    {:ok,
     socket
     |> assign(show_mobile_menu: false)
     |> assign_student_form(blank_params())}
  end

  @impl true
  def handle_event("validate", %{"student" => params}, socket) do
    {:noreply, assign_student_form(socket, normalize_params(params))}
  end

  def handle_event("save", %{"student" => params}, socket) do
    params = normalize_params(params)
    socket = assign_student_form(socket, params)

    if not socket.assigns.can_submit do
      {:noreply, put_flash(socket, :error, "Please complete all required student details.")}
    else
      case Accounts.register_student(
             %{
               "student_number" => params["student_number"],
               "first_name" => params["first_name"],
               "last_name" => params["last_name"],
               "middle_name" => params["middle_name"],
               "email" => params["email"]
             },
             notify: true
           ) do
        {:ok, user} ->
          {:noreply,
           socket
           |> put_flash(
             :info,
             "Account created. Login credentials were sent to #{user.email}."
           )
           |> push_navigate(to: ~p"/users/log-in")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
           socket
           |> assign_student_form(params, changeset)
           |> put_flash(:error, "Could not create account. Check the form for errors.")}
      end
    end
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  defp blank_params do
    %{
      "student_number" => "",
      "first_name" => "",
      "last_name" => "",
      "middle_name" => "",
      "email" => "",
      "use_suggested_email" => "true"
    }
  end

  defp normalize_params(params) do
    params = Map.merge(blank_params(), Map.new(params, fn {k, v} -> {to_string(k), v} end))

    student_number = StudentEmail.normalize_student_number(params["student_number"])
    first_name = String.trim(to_string(params["first_name"] || ""))
    last_name = String.trim(to_string(params["last_name"] || ""))
    middle_name = String.trim(to_string(params["middle_name"] || ""))
    suggested = StudentEmail.suggest(first_name, last_name, student_number)
    use_suggested? = params["use_suggested_email"] in [true, "true", "on", "1"]

    email =
      cond do
        use_suggested? and suggested -> suggested
        true -> String.trim(to_string(params["email"] || "")) |> String.downcase()
      end

    %{
      "student_number" => student_number,
      "first_name" => first_name,
      "last_name" => last_name,
      "middle_name" => middle_name,
      "email" => email,
      "use_suggested_email" => if(use_suggested?, do: "true", else: "false")
    }
  end

  defp assign_student_form(socket, params, server_changeset \\ nil) do
    suggested =
      StudentEmail.suggest(params["first_name"], params["last_name"], params["student_number"])

    use_suggested? = params["use_suggested_email"] == "true"
    student_number_ready? = StudentEmail.valid_student_number?(params["student_number"])

    email_placeholder =
      suggested || "e.g. jd202512345@#{StudentEmail.domain()}"

    errors = form_errors(params, server_changeset)

    can_submit? =
      student_number_ready? and
        params["first_name"] != "" and
        params["last_name"] != "" and
        StudentEmail.valid_format?(params["email"]) and
        errors == []

    form =
      to_form(params,
        as: :student,
        errors: errors,
        action: if(server_changeset, do: :validate, else: nil)
      )

    socket
    |> assign(:form, form)
    |> assign(:suggested_email, suggested)
    |> assign(:use_suggested_email, use_suggested?)
    |> assign(:email_placeholder, email_placeholder)
    |> assign(:student_number_ready, student_number_ready?)
    |> assign(:can_submit, can_submit?)
  end

  defp form_errors(params, nil) do
    []
    |> maybe_error(
      :student_number,
      params["student_number"] != "" and
        not StudentEmail.valid_student_number?(params["student_number"]),
      "must be at least 6 digits"
    )
    |> maybe_error(
      :email,
      params["email"] != "" and not StudentEmail.valid_format?(params["email"]),
      "must be a valid email address"
    )
  end

  defp form_errors(_params, %Ecto.Changeset{} = changeset) do
    changeset
    |> Map.put(:action, :validate)
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", stringify_error_value(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message -> {field, {message, []}} end)
    end)
  end

  defp stringify_error_value(value) when is_binary(value), do: value
  defp stringify_error_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_error_value(value) when is_integer(value), do: Integer.to_string(value)

  defp stringify_error_value(value) when is_list(value),
    do: Enum.map_join(value, ", ", &stringify_error_value/1)

  defp stringify_error_value(value), do: inspect(value)

  defp maybe_error(errors, _field, false, _message), do: errors
  defp maybe_error(errors, field, true, message), do: [{field, {message, []}} | errors]
end
