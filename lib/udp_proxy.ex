defmodule UdpProxy do
  use Application

  def start _type, _args do
    import Supervisor.Spec

    {:ok, upstream_host} =
      "UPSTREAM_HOST"
    |> System.get_env
    |> String.to_charlist
    |> :inet.parse_address

    {upstream_port, ""} =
      "UPSTREAM_PORT"
    |> System.get_env
    |> Integer.parse

    proxy_settings =
      %{upstream_host: upstream_host,
        upstream_port: upstream_port}

    children = [
      worker(UdpProxy.Server, [proxy_settings, []]),
    ]

    Supervisor.start_link children, strategy: :one_for_one, name: UdpProxy.Supervisor
  end
end
