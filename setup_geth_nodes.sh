cd geth_nodes
export DIR="./private_network"
mkdir -p ${DIR}/node1 ${DIR}/node2

cp -R accounts/account1 ${DIR}/node1/keystore
cp -R accounts/account2 ${DIR}/node2/keystore

cp genesis.json ${DIR}/genesis.json
geth init ${DIR}/genesis.json --datadir=${DIR}/node1
geth init ${DIR}/genesis.json --datadir=${DIR}/node2

NODEKEY_1=$(cat ${DIR}/node1/geth/nodekey)
ENODE_1=$(bootnode -nodekeyhex ${NODEKEY_1} -writeaddress)

NODEKEY_2=$(cat ${DIR}/node2/geth/nodekey)
ENODE_2=$(bootnode -nodekeyhex ${NODEKEY_2} -writeaddress)

cat > "${DIR}/node1/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@ethereum_node1:30304?discport=0",
    "enode://${ENODE_2}@ethereum_node2:30305?discport=0"
]
EOF

cat > "${DIR}/node2/geth/static-nodes.json" << EOF
[
    "enode://${ENODE_1}@ethereum_node1:30304?discport=0",
    "enode://${ENODE_2}@ethereum_node2:30305?discport=0"
]
EOF

touch ${DIR}/password
