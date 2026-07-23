defmodule CuzCoreConnect.Registrations.RegistrationNotifier do
  @moduledoc """
  Emails the student about registration lifecycle events: submission, each
  stage approval, each stage rejection, and final completion.

  In dev/test this is delivered via `Swoosh.Adapters.Local` /
  `Swoosh.Adapters.Test` (see `config/config.exs` and `config/test.exs`), so
  nothing here requires real SMTP to verify - emails show up at
  `/dev/mailbox` in dev and can be asserted on with `Swoosh.TestAssertions`
  in tests.
  """
  import Swoosh.Email

  alias CuzCoreConnect.Mailer

  @stage_labels %{
    "payment" => "Payment",
    "academics" => "Academics",
    "hod" => "Head of Department",
    "retention" => "Retention"
  }

  defp deliver(recipient, subject, body) when is_binary(recipient) and recipient != "" do
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

  defp deliver(_recipient, _subject, _body), do: {:ok, :skipped}

  @doc "Notify the student that their registration was submitted successfully."
  def deliver_submission_email(registration) do
    deliver(
      registration.student_email,
      "Registration received - #{registration.tracking_number}",
      """

      Hi #{registration.student_names},

      We've received your registration. Your tracking number is:

          #{registration.tracking_number}

      You can track its progress at any time using this number, even without logging in.

      ==============================
      """
    )
  end

  @doc "Notify the student that a stage approved their registration."
  def deliver_stage_approved_email(registration, stage) do
    label = Map.get(@stage_labels, stage, stage)

    deliver(registration.student_email, "Registration update - #{label} approved", """

    Hi #{registration.student_names},

    Good news! The #{label} stage of your registration (#{registration.tracking_number}) has been approved.

    ==============================
    """)
  end

  @doc "Notify the student that a stage rejected their registration, with the reason given."
  def deliver_stage_rejected_email(registration, stage, reason) do
    label = Map.get(@stage_labels, stage, stage)

    deliver(registration.student_email, "Registration update - #{label} rejected", """

    Hi #{registration.student_names},

    Unfortunately the #{label} stage of your registration (#{registration.tracking_number}) was rejected.

    Reason given: #{reason || "No reason provided."}

    Please log in and revise/resubmit your registration.

    ==============================
    """)
  end

  @doc "Notify the student that their registration is fully approved/completed."
  def deliver_completion_email(registration) do
    deliver(
      registration.student_email,
      "Registration complete - #{registration.tracking_number}",
      """

      Hi #{registration.student_names},

      Congratulations! Your registration (#{registration.tracking_number}) has completed every approval stage and is now fully APPROVED.

      ==============================
      """
    )
  end
end
