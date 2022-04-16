# Geth nodes

## Basic setup

To initialize all configuration for the two mining nodes we're going to spin, run

```
make setup
```

## Accounts

Node 1 miner account:

- Address: `0xafb72ccaeb7e22c8a7640f605824b0898424b3da`
- Private key: `e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c`

Node 2 miner account:

- Address: `0x77b648683cde1d69544ed6f4f7204e8d51c324db`
- Private key: `f71d3dd32649f9bdfc8e4a5232d3f245860243756f96fbe070c31fc44c9293f4`

To run the nodes:

```
make node1
```

and on a separate tab

```
make node2
```

## Attaching to the nodes

With the nodes running, you can attach to them and get a Geth JS console by doing

```
make node1_attach
```

and similarly for node2. On this console, you can give funds to any account you wish by transferring from one of the etherbase accounts to the desired one. To do so, first run

```
personal.unlockAccount(eth.coinbase)
```

to unlock the etherbase account. Then run

```
eth.sendTransaction({from:eth.coinbase, to:"<account_address>", value: web3.toWei(2, "ether") , gas: 40000 });
```

## Resetting nodes

To wipe all node data and start over, run

```
make clean
```
