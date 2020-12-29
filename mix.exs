defmodule MessageBounceBenchmark.MixProject do
  use Mix.Project

  def project do
    [
      app: :message_bounce_benchmark,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MessageBounceBenchmark.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      distillery: "~> 2.1",
      libcluster: "~> 3.2"
    ]
  end
end
