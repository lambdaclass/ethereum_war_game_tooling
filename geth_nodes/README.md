# Geth nodes

## Basic setup

To initialize all configuration for the two mining nodes we're going to spin, run

```
make setup
```

When prompted, enter passwords for the two eth accounts that are created (I recommend empty passwords, as they don't really matter).

Take note of both accounts' addresses, which are going to be the `etherbase` accounts for our two nodes (an etherbase account is the account where the eth gained from mining goes).

To run the nodes:

```
make node1 ETHERBASE_1=<etherbase_account_1_address>
```

and on a separate tab

```
make node2 ETHERBASE_1=<etherbase_account_2_address>
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