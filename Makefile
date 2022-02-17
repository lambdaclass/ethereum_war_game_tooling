init:
	curl -L https://foundry.paradigm.xyz | bash
	git submodule init
	git submodule update
	(cd hh_node && npm install --save-dev hardhat)
eth_node:
	(cd hh_node && npx hardhat node)
deploy_test_contract:
	forge create --rpc-url http://127.0.0.1:8545 Storage --root contracts/ --private-key df57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e