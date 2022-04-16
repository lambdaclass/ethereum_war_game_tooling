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

deploy_test_contract:
	forge create --rpc-url http://127.0.0.1:8545 Storage --root contracts/ --private-key e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c
