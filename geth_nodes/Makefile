.PHONY: setup node1 node2 clean node1_attach node2_attach

setup:
	./setup_geth_nodes.sh

node1:
	geth --datadir ./private_network/node1 --networkid 1234 --port 30304 --nodiscover --http --http.addr 127.0.0.1 --http.port 8545 --ipcpath ./private_network/node1/geth.ipc --mine --miner.threads 1 --miner.gasprice "10000" --miner.etherbase ${ETHERBASE_1} --verbosity 5 --allow-insecure-unlock --fakepow

node2:
	geth --datadir ./private_network/node2 --networkid 1234 --port 30305 --nodiscover --http --http.addr 127.0.0.1 --http.port 8546 --ipcpath ./private_network/node2/geth.ipc --mine --miner.threads 1 --miner.gasprice "10000" --miner.etherbase ${ETHERBASE_2} --verbosity 5 --allow-insecure-unlock --fakepow

clean:
	rm -rf private_network

node1_attach:
	(cd private_network/node1 && geth attach ipc:geth.ipc)

node2_attach:
	(cd private_network/node2 && geth attach ipc:geth.ipc)
