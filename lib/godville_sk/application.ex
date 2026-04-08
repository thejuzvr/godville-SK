defmodule GodvilleSk.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GodvilleSkWeb.Telemetry,
      GodvilleSk.Repo,
      {DNSCluster, query: Application.get_env(:godville_sk, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GodvilleSk.PubSub},
      {DynamicSupervisor, name: GodvilleSk.HeroSupervisor, strategy: :one_for_one},
      GodvilleSkWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: GodvilleSk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GodvilleSkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
