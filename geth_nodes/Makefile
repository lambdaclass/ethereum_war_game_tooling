.PHONY: setup node1 node2 clean node1_attach node2_attach

setup:
	./setup_geth_nodes.sh

up:
	docker-compose up

clean:
	rm -rf ./private_network

node1_attach:
	docker exec -it geth_nodes-ethereum_node1-1 /bin/sh -c "geth attach /root/private_network/node1/geth.ipc"

node2_attach:
	docker exec -it geth_nodes-ethereum_node2-1 /bin/sh -c "geth attach /root/private_network/node2/geth.ipc"
