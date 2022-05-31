defmodule EthClient.WebSocket do
  use WebSockex
  alias EthClient.Context
  @wsocket "wss://rinkeby.infura.io/ws/v3/59d4079d3a294989b61401bf97785af6"

  def start_link(state \\ []) do
    WebSockex.start_link(@wsocket, __MODULE__, state)
  end

  def suscribe(client) do
    address = Context.contract() |> Map.get(:address)

    {:ok, frame} =
      Jason.encode(%{
        jsonrpc: "2.0",
        id: 1,
        method: "eth_subscribe",
        params: ["logs", %{address: address}]
      })

    WebSockex.send_frame(client, {:text, frame})
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  def handle_frame({_type, msg}, state) do
    msg = decode_msg(msg)

    IO.puts("Log received\n")
    IO.puts("address: #{msg["address"]}\ndata: #{msg["data"]}\nTopic: #{msg["topics"]}")
    {:ok, state}
  end

  defp decode_msg(msg) do
    msg
    |> Jason.decode!()
    |> get_in(["params", "result"])
  end
end
