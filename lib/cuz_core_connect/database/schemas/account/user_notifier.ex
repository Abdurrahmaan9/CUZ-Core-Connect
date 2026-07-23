defmodule CuzCoreConnect.Accounts.UserNotifier do
  import Swoosh.Email

  alias CuzCoreConnect.Mailer
  alias CuzCoreConnect.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"CUZ - Core Connect", "contact@cuz.coreconnect.edu"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver temporary login credentials after an admin creates an account.
  In development this lands in the local Swoosh mailbox at `/dev/mailbox`.
  """
  def deliver_account_credentials(user, password, login_url)
      when is_binary(password) and is_binary(login_url) do
    name = user.username || user.email

    deliver(user.email, "Your CUZ Core Connect account", """

    ==============================

    Hi #{name},

    An account has been created for you on CUZ Core Connect.

    Email:    #{user.email}
    Username: #{user.username}
    Role:     #{user.user_role}
    Password: #{password}

    Sign in here:
    #{login_url}

    Please change your password after your first login.

    If you did not expect this email, contact the system administrator.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
