defmodule UdpProxy.Upstream do
  use GenServer
  alias UdpProxy.Server

  def start_link upstream_host, upstread_port, downstream, opts \\ [] do
    GenServer.start_link __MODULE__, {upstream_host, upstread_port, downstream}, opts
  end

  def init {upstream_host, upstream_port, downstream} do
    {:ok, socket} = :gen_udp.open 0, [:binary, {:active, true}]
    state = %{socket: socket,
              upstream_host: upstream_host,
              upstream_port: upstream_port,
              downstream: downstream}
    {:ok, state}
  end

  def send_data upstream, data do
    GenServer.cast upstream, {:send, data}
  end

  def close upstream do
    GenServer.cast upstream, :close
  end

  def handle_cast {:send, data}, state do
    :ok = :gen_udp.send state[:socket], state[:upstream_host], state[:upstream_port], data
    {:noreply, state}
  end

  def handle_cast :close, state do
    {:stop, :normal, state}
  end

  def handle_info {:udp, _socket, _ip, _port, data}, state do
    Server.receive_data state[:downstream], data
    {:noreply, state}
  end

  def handle_info {:udp_passive, _socket}, state do
    {:noreply, state}
  end
end
