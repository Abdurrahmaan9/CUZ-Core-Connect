defmodule CuzCoreConnectWeb.ReceiptController do
  use CuzCoreConnectWeb, :controller

  alias CuzCoreConnect.Registrations

  def show(conn, %{"id" => id}) do
    case Registrations.get_payment_receipt(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Receipt not found")

      receipt ->
        # Try reading the stored path directly; if that fails, try priv/static/uploads/<storage_key>
        storage_path = receipt.storage_key || ""

        paths_to_try = [storage_path, Path.join([:code.priv_dir(:cuz_core_connect) |> to_string(), "static", "uploads", storage_path])]

        result = Enum.find_value(paths_to_try, fn path ->
          case File.read(path) do
            {:ok, data} -> {:ok, data}
            _ -> nil
          end
        end)

        case result do
          {:ok, data} ->
            conn
            |> put_resp_content_type(receipt.content_type)
            |> send_resp(200, data)

          _ ->
            conn
            |> put_status(:not_found)
            |> text("Receipt not found")
        end
    end
  end
end
