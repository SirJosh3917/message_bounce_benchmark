defmodule MessageBounceBenchmark.Application do
  @moduledoc false

  use Application

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    topologies = [
      gossip_example: [
        strategy: Elixir.Cluster.Strategy.Gossip,
        config: [
          secret: "MessageBounceBenchmark"
        ]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: MessageBounceBenchmark.ClusterSupervisor]]},
      {NodePartitioner, name: NodePartitioner}
    ]

    opts = [strategy: :one_for_one, name: MessageBounceBenchmark.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
