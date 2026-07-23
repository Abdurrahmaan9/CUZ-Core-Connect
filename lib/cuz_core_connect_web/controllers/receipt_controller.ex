defmodule CuzCoreConnectWeb.ReceiptController do
  use CuzCoreConnectWeb, :controller

  alias CuzCoreConnect.Registrations

  # Staff roles allowed to review any student's payment receipt.
  @staff_roles ~w(admin academics finance hod retention)

  def show(conn, %{"id" => id}) do
    with %{} = user <- conn.assigns[:current_scope] && conn.assigns.current_scope.user,
         receipt when not is_nil(receipt) <- Registrations.get_payment_receipt(id),
         :ok <- authorize(user, receipt),
         {:ok, data, _path} <- Registrations.read_receipt_file(receipt) do
      filename = receipt.original_filename || "receipt"

      conn
      |> put_resp_content_type(receipt.content_type || "application/octet-stream")
      |> put_resp_header("content-disposition", ~s(inline; filename="#{filename}"))
      |> send_resp(200, data)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> text(
          "Receipt file is missing on the server. Ask the student to resubmit the registration with the receipt."
        )

      _ ->
        conn
        |> put_status(:not_found)
        |> text("Receipt not found")
    end
  end

  defp authorize(user, receipt) do
    cond do
      user.user_role in @staff_roles -> :ok
      owns_receipt?(user, receipt) -> :ok
      true -> :error
    end
  end

  defp owns_receipt?(user, receipt) do
    with %{student_registration_id: registration_id} <- receipt,
         registration when not is_nil(registration) <-
           Registrations.get_registration(registration_id) do
      Registrations.owns_registration?(user, registration)
    else
      _ -> false
    end
  end
end
