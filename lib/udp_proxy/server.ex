defmodule UdpProxy.Server do
  use GenServer
  alias UdpProxy.Upstream

  def start_link state, opts \\ [] do
    GenServer.start_link __MODULE__, state, opts
  end

  def init state do
    {:ok, socket} = :gen_udp.open 21337, [:binary, {:active, true}]
    state =
      state
    |> Map.put(:socket, socket)
    |> Map.put(:map, %{})
    |> Map.put_new(:gc_hz, 1000)
    |> Map.put_new(:inactivity_ttl, 5)
    Process.send_after self, :gc, 1
    {:ok, state}
  end

  def receive_data downstream, data do
    GenServer.cast downstream[:pid], {:receive, downstream, data}
  end

  def handle_cast {:receive, downstream, data}, state do
    :ok = :gen_udp.send state[:socket], downstream[:host], downstream[:port], data
    {:noreply, state}
  end

  def handle_info :gc, state do
    map =
      state[:map]
    |> Enum.filter(fn {_key, upstream} ->
      if DateTime.to_unix(DateTime.utc_now) - upstream[:last_activity] < state[:inactivity_ttl] do
        true
      else
        Upstream.close upstream[:pid]
        false
      end
    end)
    |> Enum.into(%{})
    state = Map.put state, :map, map
    Process.send_after self, :gc, state[:gc_hz]
    {:noreply, state}
  end

  def handle_info {:udp, _socket, ip, port, data}, state do
    map_key = {ip, port}
    server = self
    upstream = Map.get_lazy state[:map], map_key, fn ->
      downstream = %{pid: server,
                     host: ip,
                     port: port}
      {:ok, pid} = Upstream.start_link state[:upstream_host], state[:upstream_port], downstream
      %{pid: pid}
    end
    upstream = Map.put upstream, :last_activity, DateTime.to_unix(DateTime.utc_now)
    map = Map.put state[:map], map_key, upstream
    state = Map.put state, :map, map
    Upstream.send_data upstream[:pid], data
    {:noreply, state}
  end

  def handle_info {:udp_passive, _socket}, state do
    {:noreply, state}
  end
end
