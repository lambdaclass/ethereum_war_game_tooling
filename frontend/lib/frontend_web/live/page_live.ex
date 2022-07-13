defmodule FrontendWeb.PageLive do
  use Phoenix.LiveView

  alias Frontend.Contract
  alias Frontend.Method

  def render(assigns) do
    FrontendWeb.PageView.render("form.html", assigns)
  end

  def mount(_params, _args, socket) do
    latest_contract = Contract.get_latest()
    contract_address = latest_contract.address
    {:ok, abi} = Jason.decode(latest_contract.abi)
    {:ok, parsed_abi} = parse_abi(abi)

    assigns = [
      conn: socket,
      account_address: "0xAfB72cCAEB7e22c8A7640F605824B0898424b3Da",
      private_key: "e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c",
      chain_id: 5,
      chain_url: "https://eth-goerli.g.alchemy.com/v2/p-I7_XVkEMtyU--9k8cXeiq7XgwbZlgD",
      contract_address: contract_address,
      parsed_abi: parsed_abi
    ]

    EthClient.Context.set_chain_id(assigns[:chain_id])
    EthClient.Context.set_rpc_host(assigns[:chain_url])
    EthClient.Context.set_contract_address(latest_contract.address)

    EthClient.Context.set_user_account(%EthClient.Account{
      address: assigns[:account_address],
      private_key: assigns[:private_key]
    })

    socket = assign(socket, assigns)

    {:ok, socket}
  end

  def handle_event("deploy_contract", params, socket) do
    # contract_bin = "/Users/lambda/Documents/ethereum_playground/eth_client/bin/GameItem.bin"
    contract_bin = "/Users/lambda/Documents/ethereum_playground/contracts/src/bin/Storage.bin"
    # contract_abi = "/Users/lambda/Documents/ethereum_playground/eth_client/bin/GameItem.abi"
    contract_abi = "/Users/lambda/Documents/ethereum_playground/contracts/src/bin/Storage.abi"

    {:ok, file} = File.read(contract_abi)
    {:ok, abi} = Jason.decode(file)

    {:ok, parsed_abi} = parse_abi(abi)

    contract =
      %{address: address, functions: functions} = EthClient.deploy(contract_bin, contract_abi)

    {:ok, _contract} =
      Contract.create(%{
        address: address,
        abi: file,
        name: "name"
      })

    socket = assign(socket, :contract_address, address)
    socket = assign(socket, :contract, contract)
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
    method = socket.assigns.parsed_abi[method_name]
    {:ok, result} = call_or_invoke(method, method_params) |> IO.inspect()

    {:noreply, socket}
  end

  defp call_or_invoke(%{mutability: mutability} = method, params)
       when mutability in ["view", "pure"] do
    arguments =
      Enum.map(method.arguments, fn {argument_name, _argument_type} ->
        params[Atom.to_string(argument_name)]
      end)

    Method.call(method, arguments)
  end

  defp call_or_invoke(method, params) do
    arguments =
      Enum.map(method.arguments, fn {argument_name, argument_type} ->
        params[Atom.to_string(argument_name)] |> parse_argument(argument_type)
      end)

    amount = String.to_integer(params["Amount"])

    Method.invoke(method, arguments, amount)
  end

  defp parse_argument(argument, "uint"), do: String.to_integer(argument)
  defp parse_argument(argument, "uint256"), do: String.to_integer(argument)
  defp parse_argument(argument, _type), do: argument

  ## The context goes away, all transient state is stored in the LiveView process
  ## Contracts and config are stored in postgres, you can change the state of the liveview process
  ## by fetching from the database.

  ## This will mean refactoring the EthClient to get rid of the context and maybe
  ## make a different "CLI" app to use through the command line.

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
