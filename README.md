# Ethereum Playground

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
