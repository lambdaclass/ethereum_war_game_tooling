defmodule FrontendWeb.ContractLive do
  use Phoenix.LiveView

  alias Frontend.Contract
  alias Frontend.Method
  alias EthClient.Rpc
  alias Frontend.Chain
  alias ABI.TypeDecoder
  alias FrontendWeb.Router.Helpers, as: Routes

  def render(assigns) do
    FrontendWeb.ContractView.render("form.html", assigns)
  end

  def mount(_params, %{"config_id" => config_id} = params, socket) do
    chain_config = Chain.get_config!(config_id)

    ## Fix this
    contract =
      if params["contract_id"] do
        Contract.by_id(params["contract_id"])
      else
        Contract.get_latest()
      end

    ## Fix this
    parsed_abi =
      if contract do
        {:ok, abi} = Jason.decode(contract.abi)
        {:ok, parsed_abi} = parse_abi(abi)
        parsed_abi
      else
        nil
      end

    assigns = [
      conn: socket,
      chain_config: chain_config,
      contract: contract,
      parsed_abi: parsed_abi
    ]

    socket = assign(socket, assigns)
    socket = update_balance(socket, chain_config)

    socket =
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:contract_bin, accept: :any, max_entries: 2)
      |> allow_upload(:contract_abi, accept: :any, max_entries: 2)

    {:ok, socket}
  end

  def handle_event("deploy_contract", params, socket) do
    [bin_static_path] =
      consume_uploaded_entries(socket, :contract_bin, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:frontend), "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")}
      end)

    contract_bin = Path.join([:code.priv_dir(:frontend), "static", bin_static_path])

    [abi_static_path] =
      consume_uploaded_entries(socket, :contract_abi, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:frontend), "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, Routes.static_path(socket, "/uploads/#{Path.basename(dest)}")}
      end)

    contract_abi = Path.join([:code.priv_dir(:frontend), "static", abi_static_path])

    chain_config = socket.assigns.chain_config

    {:ok, file} = File.read(contract_abi)
    {:ok, abi} = Jason.decode(file)

    {:ok, parsed_abi} = parse_abi(abi)

    {:ok, tx_hash} = EthClient.deploy(chain_config, contract_bin)

    {:ok, %{"contractAddress" => contract_address}} =
      Rpc.wait_for_confirmation(chain_config.rpc_host, tx_hash)

    {:ok, contract} =
      Contract.create(%{
        address: contract_address,
        abi: file,
        name: params["contract"]["name"]
      })

    socket = assign(socket, :contract, contract)
    socket = assign(socket, :parsed_abi, parsed_abi)
    {:noreply, socket}
  end

  def handle_event(
        "contract_change",
        %{
          "_target" => ["contract", "contract_name"],
          "contract" => %{"contract_name" => contract_name}
        },
        socket
      ) do
    contract = Contract.by_name(contract_name)

    {:ok, abi} = Jason.decode(contract.abi)
    {:ok, parsed_abi} = parse_abi(abi)

    assigns = [
      contract_address: contract.address,
      parsed_abi: parsed_abi
    ]

    {:noreply, assign(socket, assigns)}
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
    contract = socket.assigns.contract
    method = socket.assigns.parsed_abi[method_name]

    {:ok, _result} =
      call_or_invoke(chain_config, contract.address, method, method_params) |> IO.inspect()

    {:noreply, socket}
  end

  defp call_or_invoke(chain_config, contract_address, %{mutability: mutability} = method, params)
       when mutability in ["view", "pure"] do
    arguments =
      Enum.map(method.arguments, fn {argument_name, _argument_type} ->
        params[Atom.to_string(argument_name)]
      end)

    {:ok, result_encoded} = Method.call(chain_config, contract_address, method, arguments)
    ## FIXME: For now I'm assuming there is only one return value; there could be multiple
    [output_type | _] = Keyword.values(method.outputs)
    {:ok, decode_result(result_encoded, output_type)}
  end

  defp decode_result(encoded, "uint"), do: decode_result(encoded, "uint256")

  defp decode_result(encoded, "uint256") do
    encoded
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first()
  end

  defp decode_result(encoded, "string") do
    encoded
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([:string])
    |> List.first()
  end

  defp decode_result(encoded, _other) do
    encoded
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

    outputs =
      Enum.reduce(method_map["outputs"], [], fn output, acc ->
        acc ++ Keyword.new([{String.to_atom(output["name"]), output["internalType"]}])
      end)

    method = Method.new(method_map["name"], arguments, method_map["stateMutability"], outputs)
    acc = Map.put(acc, method_map["name"], method)

    parse_abi(tail, acc)
  end

  defp parse_abi([_head | tail], acc) do
    parse_abi(tail, acc)
  end

  defp update_balance(socket, chain_config) do
    {:ok, "0x" <> hex_balance} = Rpc.get_balance(chain_config.rpc_host, chain_config.user_address)
    {balance, ""} = Integer.parse(hex_balance, 16)
    assign(socket, :balance, balance / 1_000_000_000_000_000_000)
  end
end
