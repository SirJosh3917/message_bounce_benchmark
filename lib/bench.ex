defmodule Bench do
  @moduledoc """
  Runs a benchmark.

  This benchmark works by having a parent node start two children, and once the parent node receives a message it will
  pass it to all the nodes it's connected to. Each child may also have two children, or none. Thus, sending a message
  into the node cluster will start an "atomic bomb" of sorts - with each node passing a message to the other and it
  gets exponentially worse until the node gets killed by the OS for running out of memory.

  The goal of the benchmark is for the first node to receive the highest number it can, which is ultimately a benchmark
  of the pre-emptive multitasking of Elixir. In languages with cooperative multitasking, the first node will typically
  not reach a high value, most likely due to the massive amount of work the other nodes have to do.
  """

  @doc """
  Starts the benchmark. The first argument does not need to be specified.
  """
  def run(node_partitioner \\ NodePartitioner) do
    me = self()

    worker = Node.spawn(NodePartitioner.next_worker(node_partitioner), fn ->
      worker(node_partitioner, me, 1)
    end)

    send(worker, 1)

    do_run(0, worker)
  end

  defp do_run(max_num, worker) do
    receive do
      num ->
        send(worker, num + 1)
        new_max = max(num, max_num)

        if new_max != max_num do
          IO.puts "#{new_max}"
        end

        do_run(new_max, worker)
    end
  end

  # cut off making child nodes at a nesting > 10
  defp worker(node_partitioner, parent, nesting) when nesting > 10 do
    receive do
      num ->
        send(parent, num + 1)
        worker(node_partitioner, parent, nesting)
    end
  end

  # make a worker node with two children
  defp worker(node_partitioner, parent, nesting) do
    me = self()

    left = Node.spawn(NodePartitioner.next_worker(node_partitioner), fn ->
      worker(node_partitioner, me, nesting + 1)
    end)

    right = Node.spawn(NodePartitioner.next_worker(node_partitioner), fn ->
      worker(node_partitioner, me, nesting + 1)
    end)

    do_worker(left, right, parent)
  end

  # loop to receive messages, and send the message back to the parent and children
  defp do_worker(left, right, parent) do
    receive do
      num ->
        send(parent, num + 1)
        send(left, num + 1)
        send(right, num + 1)
    end

    do_worker(left, right, parent)
  end
end
