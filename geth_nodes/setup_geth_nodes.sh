mkdir -p private_network/node1 private_network/node2

geth --datadir ./private_network/node1 account new   
geth --datadir ./private_network/node2 account new

cp genesis.json ./private_network/genesis.json
geth init ./private_network/genesis.json --datadir=./private_network/node1
geth init ./private_network/genesis.json --datadir=./private_network/node2

NODEKEY_1=$(cat ./private_network/node1/geth/nodekey)
ENODE_1=$(bootnode -nodekeyhex ${NODEKEY_1} -writeaddress)

NODEKEY_2=$(cat ./private_network/node2/geth/nodekey)
ENODE_2=$(bootnode -nodekeyhex ${NODEKEY_2} -writeaddress)

cat > "./private_network/node1/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@127.0.0.1:30304?discport=0",
    "enode://${ENODE_2}@127.0.0.1:30305?discport=0"
]
EOF

cat > "./private_network/node2/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@127.0.0.1:30304?discport=0",
    "enode://${ENODE_2}@127.0.0.1:30305?discport=0"
]
EOF
