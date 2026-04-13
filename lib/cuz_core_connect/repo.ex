defmodule CuzCoreConnect.Repo do
  use Ecto.Repo,
    otp_app: :cuz_core_connect,
    adapter: Ecto.Adapters.Postgres
end
