defmodule CuzCoreConnectWeb.Academics.Students.Index do
  use CuzCoreConnectWeb, :live_view

  alias CuzCoreConnect.Students.Registration
  alias CuzCoreConnect.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns[:current_scope]

    pending_registrations = list_pending_registrations()

    {:ok,
     socket
     |> assign(
       page_title: "Pending Registrations",
       current_page: :student_pending,
       current_scope: current_scope,
       pending_registrations: pending_registrations
     )}
  end

  @impl true
  def handle_event("approve_registration", %{"registration-id" => registration_id}, socket) do
    case approve_registration(registration_id) do
      {:ok, _registration} ->
        pending_registrations = list_pending_registrations()

        {:noreply,
         socket
         |> assign(:pending_registrations, pending_registrations)
         |> put_flash(:info, "Registration approved successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to approve registration")}
    end
  end

  @impl true
  def handle_event("reject_registration", %{"registration-id" => registration_id}, socket) do
    case reject_registration(registration_id) do
      {:ok, _registration} ->
        pending_registrations = list_pending_registrations()

        {:noreply,
         socket
         |> assign(:pending_registrations, pending_registrations)
         |> put_flash(:info, "Registration rejected")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject registration")}
    end
  end

  # Private functions

  defp list_pending_registrations do
    Registration
    |> where([r], r.approval_level == "pending")
    |> order_by([r], desc: r.registration_date)
    |> Repo.all()
    |> Repo.preload(:payment_receipts)
  end

  defp approve_registration(registration_id) do
    registration = Repo.get(Registration, registration_id)

    registration
    |> Ecto.Changeset.change(%{
      approval_level: "approved",
      approved_by: %{
        # Will be set with current user when auth is implemented
        user_id: nil,
        approved_at: DateTime.utc_now(),
        notes: "Approved by administrator"
      }
    })
    |> Repo.update()
  end

  defp reject_registration(registration_id) do
    registration = Repo.get(Registration, registration_id)

    registration
    |> Ecto.Changeset.change(%{
      approval_level: "rejected",
      approved_by: %{
        # Will be set with current user when auth is implemented
        user_id: nil,
        approved_at: DateTime.utc_now(),
        notes: "Rejected by administrator"
      }
    })
    |> Repo.update()
  end

  defp get_program_name(program_details) when is_map(program_details) do
    Map.get(program_details, "program_name", "Not specified")
  end

  defp get_program_name(_), do: "Not specified"

  defp format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> format_date()
  end

  defp format_date(%Date{} = date) do
    "#{date.day}#{ordinal_suffix(date.day)} #{Calendar.strftime(date, "%B %Y")}"
  end

  defp format_date(_), do: "Unknown"

  defp format_expiry_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.add(364)
    |> format_date()
  end

  defp format_expiry_date(_), do: "Unknown"

  defp ordinal_suffix(day) when day in 11..13, do: "th"
  defp ordinal_suffix(day) when rem(day, 10) == 1, do: "st"
  defp ordinal_suffix(day) when rem(day, 10) == 2, do: "nd"
  defp ordinal_suffix(day) when rem(day, 10) == 3, do: "rd"
  defp ordinal_suffix(_day), do: "th"
end
