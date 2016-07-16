defmodule UdpProxy.Mixfile do
  use Mix.Project

  def project do
    [app: :udp_proxy,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [mod: {UdpProxy, []},
     applications: []]
  end

  defp deps do
    [{:credo, "~> 0.4", only: [:dev, :test]}]
  end
end
