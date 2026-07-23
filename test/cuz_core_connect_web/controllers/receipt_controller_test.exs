defmodule CuzCoreConnectWeb.ReceiptControllerTest do
  use CuzCoreConnectWeb.ConnCase, async: true

  import CuzCoreConnect.AccountFixtures
  import CuzCoreConnect.RegistrationFixtures

  alias CuzCoreConnect.Registrations

  setup do
    registration = registration_fixture()
    %{registration: registration}
  end

  test "anonymous users cannot fetch a receipt", %{conn: conn, registration: registration} do
    {:ok, receipt} = persist_temp_receipt(registration)

    conn = get(conn, ~p"/receipts/#{receipt.id}")
    assert response(conn, 404) =~ "Receipt not found"
  end

  test "unrelated students cannot fetch another student's receipt", %{
    conn: conn,
    registration: registration
  } do
    {:ok, receipt} = persist_temp_receipt(registration)
    other_student = user_fixture(%{user_role: "student"})

    conn = conn |> log_in_user(other_student) |> get(~p"/receipts/#{receipt.id}")
    assert response(conn, 404) =~ "Receipt not found"
  end

  test "finance can view a persisted receipt file", %{conn: conn, registration: registration} do
    {:ok, receipt} = persist_temp_receipt(registration, "Wallpaper.jpg", <<255, 216, 255, 224>>)
    finance = user_fixture(%{user_role: "finance"})

    conn = conn |> log_in_user(finance) |> get(~p"/receipts/#{receipt.id}")
    assert response(conn, 200)
    assert get_resp_header(conn, "content-type") |> hd() =~ "image/jpeg"
    assert conn.resp_body == <<255, 216, 255, 224>>
  end

  test "missing file returns a clear message for staff", %{conn: conn, registration: registration} do
    {:ok, receipt} =
      Registrations.create_payment_receipt(%{
        original_filename: "gone.jpg",
        storage_key: "receipts/does-not-exist-#{System.unique_integer([:positive])}.jpg",
        content_type: "image/jpeg",
        file_size: 12,
        uploaded_by_student_id: registration.student_id,
        student_registration_id: registration.id
      })

    finance = user_fixture(%{user_role: "finance"})
    conn = conn |> log_in_user(finance) |> get(~p"/receipts/#{receipt.id}")
    assert response(conn, 404) =~ "Receipt file is missing"
  end

  test "persist_payment_receipt stores under priv/static/uploads/receipts", %{
    registration: registration
  } do
    tmp = Path.join(System.tmp_dir!(), "receipt-#{System.unique_integer([:positive])}.png")
    File.write!(tmp, <<137, 80, 78, 71>>)

    assert {:ok, receipt} =
             Registrations.persist_payment_receipt(registration, tmp, %{
               client_name: "proof.png",
               client_type: "image/png",
               client_size: 4
             })

    assert String.starts_with?(receipt.storage_key, "receipts/#{registration.id}-")
    assert File.exists?(Registrations.upload_path(receipt.storage_key))
    assert {:ok, _data, _path} = Registrations.read_receipt_file(receipt)
  after
    # cleanup is best-effort; unique names avoid collisions
    :ok
  end

  defp persist_temp_receipt(registration, filename \\ "receipt.jpg", bytes \\ <<1, 2, 3>>) do
    tmp = Path.join(System.tmp_dir!(), "receipt-#{System.unique_integer([:positive])}.bin")
    File.write!(tmp, bytes)

    Registrations.persist_payment_receipt(registration, tmp, %{
      client_name: filename,
      client_type: "image/jpeg",
      client_size: byte_size(bytes)
    })
  end
end
