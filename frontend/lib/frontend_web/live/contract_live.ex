defmodule FrontendWeb.ContractLive do
  use Phoenix.LiveView

  alias Frontend.Contract
  alias Frontend.Method
  alias EthClient.Rpc
  alias Frontend.Chain

  def render(assigns) do
    FrontendWeb.ContractView.render("form.html", assigns)
  end

  def mount(_params, %{"config_id" => config_id}, socket) do
    chain_config = Chain.get_config!(config_id)
    latest_contract = Contract.get_latest()
    contract_address = latest_contract.address
    {:ok, abi} = Jason.decode(latest_contract.abi)
    {:ok, parsed_abi} = parse_abi(abi)

    assigns = [
      conn: socket,
      chain_config: chain_config,
      contract_address: contract_address,
      parsed_abi: parsed_abi
    ]

    socket = assign(socket, assigns)

    {:ok, socket}
  end

  ## Fix this
  def handle_event("deploy_contract", params, socket) do
    contract_bin = "/Users/lambda/Documents/ethereum_playground/eth_client/bin/GameItem.bin"
    # contract_bin = "/Users/lambda/Documents/ethereum_playground/contracts/src/bin/Storage.bin"
    contract_abi = "/Users/lambda/Documents/ethereum_playground/eth_client/bin/GameItem.abi"
    # contract_abi = "/Users/lambda/Documents/ethereum_playground/contracts/src/bin/Storage.abi"

    chain_config = socket.assigns.chain_config

    {:ok, file} = File.read(contract_abi)
    {:ok, abi} = Jason.decode(file)

    {:ok, parsed_abi} = parse_abi(abi)

    {:ok, tx_hash} = EthClient.deploy(chain_config, contract_bin)

    {:ok, %{"contractAddress" => contract_address}} =
      Rpc.wait_for_confirmation(chain_config.rpc_host, tx_hash) |> IO.inspect()

    {:ok, _contract} =
      Contract.create(%{
        address: contract_address,
        abi: file,
        name: "name"
      })

    socket = assign(socket, :contract_address, contract_address)
    socket = assign(socket, :parsed_abi, parsed_abi)
    {:noreply, socket}
  end

  def handle_event("contract_change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "call_method",
        %{"method_info" => %{"method" => method_name} = method_params},
        socket
      ) do
    chain_config = socket.assigns.chain_config
    contract_address = socket.assigns.contract_address
    method = socket.assigns.parsed_abi[method_name]

    {:ok, result} =
      call_or_invoke(chain_config, contract_address, method, method_params) |> IO.inspect()

    {:noreply, socket}
  end

  defp call_or_invoke(chain_config, contract_address, %{mutability: mutability} = method, params)
       when mutability in ["view", "pure"] do
    arguments =
      Enum.map(method.arguments, fn {argument_name, _argument_type} ->
        params[Atom.to_string(argument_name)]
      end)

    Method.call(chain_config, contract_address, method, arguments)
  end

  defp call_or_invoke(chain_config, contract_address, method, params) do
    arguments =
      Enum.map(method.arguments, fn {argument_name, argument_type} ->
        params[Atom.to_string(argument_name)] |> parse_argument(argument_type)
      end)

    amount = String.to_integer(params["Amount"])

    Method.invoke(chain_config, contract_address, method, arguments, amount)
  end

  defp parse_argument(argument, "uint"), do: String.to_integer(argument)
  defp parse_argument(argument, "uint256"), do: String.to_integer(argument)
  defp parse_argument("0x" <> argument, "address"), do: Base.decode16!(argument, case: :mixed)
  defp parse_argument(argument, "address"), do: Base.decode16!(argument, case: :mixed)
  defp parse_argument(argument, _type), do: argument

  defp parse_abi(abi), do: parse_abi(abi, %{})

  defp parse_abi([], acc), do: {:ok, acc}

  defp parse_abi([%{"type" => "function"} = method_map | tail], acc) do
    arguments =
      Enum.reduce(method_map["inputs"], [], fn input, acc ->
        acc ++ Keyword.new([{String.to_atom(input["name"]), input["internalType"]}])
      end)

    method = Method.new(method_map["name"], arguments, method_map["stateMutability"])
    acc = Map.put(acc, method_map["name"], method)

    parse_abi(tail, acc)
  end

  defp parse_abi([_head | tail], acc) do
    parse_abi(tail, acc)
  end
end
