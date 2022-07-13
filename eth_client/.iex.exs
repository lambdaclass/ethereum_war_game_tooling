alias EthClient
alias EthClient.Context
alias EthClient.Contract
alias EthClient.Account
alias EthClient.ChainConfig

bin_path = "../contracts/src/bin/Storage.bin"
abi_path = "../contracts/src/bin/Storage.abi"

chain_info =
  ChainConfig.new(
    %Account{
      address: System.fetch_env!("ETH_USER_ADDRESS"),
      private_key: System.fetch_env!("ETH_USER_PK")
    },
    5,
    System.fetch_env!("ETH_RPC_HOST")
  )
