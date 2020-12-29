defmodule NodePartitioner do
  @moduledoc """
  The `NodePartitioner` module handles rotating the nodes in the cluster to give a fair node to schedule a process on.

  There are many nodes in the cluster, and each node is capable of different amounts of capacity.
  To fairly schedule this, `System.schedulers/0` is executed on the target node to figure out how many schedulers there are.
  Then, that node is put into the list of "available nodes" that many times. This is repeated for each node in the cluster.
  Thus, fairly scheduling more work to nodes that can handle more work.

  Simply calling `NodePartitioner.next_worker/1` with no arguments will get an available node. If all nodes in the cluster
  have been iterated over, the partitioner will re-iterate over the nodes.

  TODO: it may be considered to use something like `swarm` for delegation or whatnot

  ## Examples

      iex> Node.ping NodePartitioner.next_worker
      :pong

  """

  use GenServer

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Gets a node to schedule work onto. If a node has more than one scheduler, it will be returned as many times as it has schedulers.
  """
  def next_worker(server \\ NodePartitioner) do
    GenServer.call(server, :next)
  end

  @impl true
  @doc false
  def init(:ok) do
    {:ok, get_available_nodes()}
  end

  @impl true
  @doc false
  def handle_call(:next, sender, []) do
    handle_call(:next, sender, get_available_nodes())
  end

  @impl true
  @doc false
  def handle_call(:next, sender, [node] ++ nodes) do
    if Node.ping(node) == :pang do
      handle_call(:next, sender, nodes)
    else
      {:reply, node, nodes}
    end
  end

  @doc """
  Takes the current node and connected nodes (with `Node.list/0`), this will

  1. Find how many schedulers a node has
  2. Repeat that node in the list for as many times it has schedulers
  3. Return it as a list
  """
  defp get_available_nodes do
    ([node()] ++ Node.list())
    |> Stream.map(fn node -> {node, schedulers_of(node)} end)
    |> Stream.map(fn {node, schedulers_available} ->
      Stream.cycle([0])
      |> Stream.take(schedulers_available)
      |> Stream.map(fn _ -> node end)
    end)
    |> Stream.flat_map(fn node -> node end)
    |> Enum.to_list()
  end

  @doc """
  Executes `System.schedulers/0` on a target node and returns how many schedulers that node has
  """
  @spec schedulers_of(node()) :: number()
  defp schedulers_of(target) do
    me = self()
    Node.spawn_link(target, fn -> send(me, {:schedulers_of, target, System.schedulers()}) end)

    receive do
      {:schedulers_of, ^target, schedulers} -> schedulers
    end
  end
end
