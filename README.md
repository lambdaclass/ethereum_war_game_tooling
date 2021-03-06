# Ethereum War Game and CTF Tooling

## EthClient

Simple elixir client to interact with the ethereum blockchain, deploying and calling smart contracts.

## Requirements
- Erlang/OTP 24
- Elixir 1.13.0
- Rust 1.58.0
- [Geth](https://geth.ethereum.org/docs/install-and-build/installing-geth)

## Quick Start with Tilt

*"I just want to try it right now!!"*

Run the following commands to get started. This will configure and start both Ethereum nodes, the Livebook server and the EthClient Elixir application. 

```bash
git clone git@github.com:lambdaclass/ethereum_war_game_tooling.git
cd ethereum_war_game_tooling
tilt up
```
Now that you have everything ready you can start playing with the tool in **one of two ways**. 

#### <ins>Livebook</ins>
Accesing to the Application running at http://localhost:8080 and creating a new notebook.

#### <ins>Elixir IEx terminal</ins>

```bash
cd eth_client
make tilt.up
```  

### Configuration

All global configuration is kept in the `EthClient.Context` module, which holds the following values:

- `rpc_host`: The hostname needed to interact with the ethereum Json RPC API. This can be an infura-type url or just the hostname of an actual node.
- `chain_id`: The id of the chain currently in use (`1` for mainnet, `4` for Rinkeby, etc).
- `user_account`: A value of type `EthClient.Account`, which holds two fields, `address` and `private_key`. This is the account used to sign and send all transactions.
- `contract`: A value of type `EthClient.Contract`, which holds two fields, `address` and `functions`.

You can change any of these config values at runtime by using the functions exposed by the `EthClient.Context` module.

The default config assumes you're running the local ethereum network this repo provides.

If you want to use infura-type host this are the setps you must follow:

First set your infura api key

```
Context.set_infura_api_key("your_infura_api_key")
```

Then set the your etherscan api key

```
Context.set_etherscan_api_key("your_eth_scan_api_key")
```

And finally set the name of the chain you want to use, for now this are the supported chains: eht mainnet, rinkeby and ropsten.

```
EthClient.set_chain("chain_name")
```

### Interacting with smart contracts

#### <a name="without_an_abi"></a>Without an ABI file
Currently there are three functions in the `EthClient` module that form the main API:

- `EthClient.deploy(bin_path)` deploys a compiled smart contract given a path to its `.bin` file, generated by compiling said contract (i.e. by running something like `solc --bin contract.sol`). After a successful deployment, the context will be updated to use it.

- `EthClient.call(method, arguments)` calls any read-only public method of a contract.

- `EthClient.invoke(method, arguments, amount)` calls any public method of a contract that requires a transaction (usually to write stuff to the blockchain). The `amount` parameter controls how much `eth` is sent to the contract.

#### With an ABI file
When there is an `.abi` file with the ABI of the contract, user can interact with API in a different way:

- `EthClient.deploy(bin_path, abi_path)` deploys a compiled smart contract (as it is explained in [Without an ABI file](#without_an_abi) section) but it also add contract functions to the context when deploying it.

- Then, user can interact with contract functions by calling `Context.contract.functions.contract_function_name.(parameters)`, either if it is a read-only method or not.

### Example

When running `iex -S mix`, there will be a default `bin_path` variable loaded with the path to a compiled `Storage` contract and a default `abi_path` variable with the path to contract's ABI. You can then immediately deploy it with

```
EthClient.deploy(bin_path)
```

and then call each of its functions. If you're running the local ethereum network, you should see something like the following:

```
iex(1)> EthClient.deploy(bin_path)
19:53:26.918 [info]  Deployment transaction accepted by the network, tx_hash: 0x14765466533a85c90ce45dd966854dc5fb95543ba97f343f389872c64ed9597b
19:53:26.922 [info]  Waiting for confirmation...
19:53:28.931 [info]  Contract deployed, address: 0x69148897094941cfad7fd3d52c5e1a810ba4e123 Current contract updated
:ok
```

```
iex(2)> EthClient.call("test_function()", [])
{:ok, "0x0000000000000000000000000000000000000000000000000000000000000001"}
```

```
iex(3)> EthClient.invoke("store(uint256)", [20], 0)
19:55:28.127 [info]  Transaction accepted by the network, tx_hash: 0x137320dcfb61055313f73aafa799670a4d172936bc91200ebf7a95092f77c297
19:55:28.127 [info]  Waiting for confirmation...
19:55:41.177 [info]  Transaction confirmed!
{:ok, "0x137320dcfb61055313f73aafa799670a4d172936bc91200ebf7a95092f77c297"}
```

```
iex(4)> EthClient.call("retrieve()", [])
{:ok, "0x0000000000000000000000000000000000000000000000000000000000000014"}
```

## Local nodes
Install dependencies with

```
make init
```

then source your `.bashrc`, `.zshrc` or similar files to add foundry to your `PATH`, then run `foundryup` to install `forge` and `cast`.

To run two local Ethereum nodes:

```
cd geth_nodes
make setup
make up
```

## Accounts
You can use the miner accounts to pay for transactions.

Node 1 miner account

- Address: `0xafb72ccaeb7e22c8a7640f605824b0898424b3da`
- Private key: `e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c`

Node 2 miner account:

- Address: `0x77b648683cde1d69544ed6f4f7204e8d51c324db`
- Private key: `f71d3dd32649f9bdfc8e4a5232d3f245860243756f96fbe070c31fc44c9293f4`


## Test contract

You can then deploy the test contract with

```
make deploy_test_contract
```

under the root directory.

The code for this contract is in `contracts/src/Storage.sol`; it has 3 functions: `test_function` will always return `1`, `store(uint256)` stores the given number and `retrieve()` returns said number.

The output should look like this

```
forge create --rpc-url http://127.0.0.1:8545 Storage --root contracts/ --private-key df57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e
compiling...
Compiling 1 files with 0.8.10
Compilation finished successfully
Compiler run successful
success.
Deployer: 0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199
Deployed to: 0xb581c9264f59bf0289fa76d61b2d0746dce3c30d
Transaction hash: 0xe2c19a2f0766c0e00c416433a8cf53c9993fc918e2b321f348d8de421c195416
```

Take note of the address you are given after `Deployed to:`, as that is the contract's address in the local chain.
With it, you can now call its test function using `cast` like this:

```
cast call <contract_address> "test_function()(uint256)" --rpc-url http://localhost:8545
```

which should return `1`.


You can also send a transaction to call the `store` function

```
cast send <contract_address> --private-key <private_key> "store(uint256)" 5 --rpc-url http://localhost:8545
```

where the private key needs to have some funds to pay for the transaction (for this you can use one of the miner accounts). Output should look like this

```
blockHash            "0xd2f9afae4ef28c63ceccd7575c4370c17ead74448567ca651ec82a7051434e01"
blockNumber          "0x5"
contractAddress      null
cumulativeGasUsed    "0x6746"
effectiveGasPrice    "0xd1790ced"
gasUsed              "0x6746"
logs                 []
logsBloom            "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
root                 null
status               "0x1"
transactionHash      "0x0bc2448d1f7ee4be24bae1201e687d937d5f094af5e64f09ca0b279d62bf0b81"
transactionIndex     "0x0"
type                 "0x2"
```

After storing a number, you can retrieve it with

```
cast call <contract_address> "retrieve()(uint256)" --rpc-url http://localhost:8545
```
### Code

Apart from EthClient calls, other modules can be called.

- RPC module handles RPC calls to the node.
- ABI module is a helper used to get the ABI of the desired contract, either calling to etherscan or locally.
- The Contract module uses the ABI module to generate elixir functions that invoke/call the said methods in the contract.
- The Account module defines a struct for accounts
- The Context module saves the current context, ie. contract ABI and address, and is updated as used. It is maintained with a Supervisor process.
- The RawTransaction module handles encoding of transactions for sending. (via RPC module)
- The Application module handles environment
