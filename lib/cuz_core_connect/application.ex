defmodule CuzCoreConnect.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Cachex.Spec

  @impl true
  def start(_type, _args) do
    children = [
      CuzCoreConnectWeb.Telemetry,
      CuzCoreConnect.Repo,
      {DNSCluster, query: Application.get_env(:cuz_core_connect, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CuzCoreConnect.PubSub},
      # Start a worker by calling: CuzCoreConnect.Worker.start_link(arg)
      # {CuzCoreConnect.Worker, arg},
      # Start to serve requests, typically the last entry
      CuzCoreConnectWeb.Endpoint,
      # cachex for keeping token in the memory
      Supervisor.child_spec(
        {Cachex,
         name: :cuz_core_connect_cache, opts: [expiration: expiration(interval: :timer.minutes(10))]},
        id: :cuz_core_connect_cache
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CuzCoreConnect.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CuzCoreConnectWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
