alias EthClient
alias EthClient.Context
alias EthClient.Contract

bin_path = "../contracts/src/bin/Storage.bin"
abi_path = "../contracts/src/bin/Storage.abi"

# Uncomment and fill in for Rinkeby
Context.set_infura_api_key("your_infura_api_key")
Context.set_etherscan_api_key("your_eth_scan_api_key")
EthClient.set_chain("rinkeby")
