.PHONY: init, deploy_test_contract

init:
	curl -L https://foundry.paradigm.xyz | bash
	git submodule init
	git submodule update

deploy_test_contract:
	forge create --rpc-url http://127.0.0.1:8545 Storage --root contracts/ --private-key e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c
