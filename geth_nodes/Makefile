.PHONY: setup node1 node2 clean node1_attach node2_attach

setup:
	./setup_geth_nodes.sh

up:
	docker-compose up

clean:
	rm -rf ./private_network

node1_attach:
	(cd ./private_network/node1 && geth attach ipc:geth.ipc)

node2_attach:
	(cd ./private_network/node2 && geth attach ipc:geth.ipc)
