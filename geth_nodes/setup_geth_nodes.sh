mkdir -p private_network/node1 private_network/node2

cp -R accounts/account1 ./private_network/node1/keystore
cp -R accounts/account2 ./private_network/node2/keystore

cp genesis.json ./private_network/genesis.json
geth init ./private_network/genesis.json --datadir=./private_network/node1
geth init ./private_network/genesis.json --datadir=./private_network/node2

NODEKEY_1=$(cat ./private_network/node1/geth/nodekey)
ENODE_1=$(bootnode -nodekeyhex ${NODEKEY_1} -writeaddress)

NODEKEY_2=$(cat ./private_network/node2/geth/nodekey)
ENODE_2=$(bootnode -nodekeyhex ${NODEKEY_2} -writeaddress)

cat > "./private_network/node1/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@ethereum_node1:30304?discport=0",
    "enode://${ENODE_2}@ethereum_node2:30305?discport=0"
]
EOF

cat > "./private_network/node2/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@ethereum_node1:30304?discport=0",
    "enode://${ENODE_2}@ethereum_node2:30305?discport=0"
]
EOF

touch private_network/password
