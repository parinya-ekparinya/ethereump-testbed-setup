#!/bin/bash

source $PWD/env.py
source $PWD/setup_utils.sh

add_peer_by_ip()
{
    local CLIENT_NAME=$1
    local SERVER_NAME=$2
    local LISTENER_IP=$3
    local CLIENT_IP=$(grep -e "^$CLIENT_NAME,${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
    local SERVER_IP=$(grep -e "^$SERVER_NAME,${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
    bin/add_peer --client $CLIENT_IP --server $SERVER_IP --listener $LISTENER_IP
}

add_peer()
{
    local CLIENT_NAME=$1
    local SERVER_NAME=$2
    local NETWORK_NAME=$3
    local LISTENER_IP=$(grep -e "^$SERVER_NAME,${NETWORK_NAME}" $VM_IP_FILE | cut -d',' -f3)
    add_peer_by_ip $1 $2 $LISTENER_IP
}

add_peers()
{
    local NODES=( ${!1} )
    local TARGET=$2
    local NETWORK_NAME=$3
    for client in ${NODES[@]}
    do
        if [ ! "$client" == "$TARGET" ] ; then
            echo "$client,$TARGET"
            add_peer $client $TARGET $NETWORK_NAME &
        fi
    done
}

peer_nodes()
{
    local NODES=( ${!1} )
    local NETWORK_NAME=$2
    for target in ${NODES[@]}
    do
        add_peers NODES[@] $target $NETWORK_NAME &
    done
    wait
}

new_accounts()
{
    local INSTANCES=$(grep -e "${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
    for instance in $INSTANCES
    do
        echo $instance
        bin/new_account --rpcaddr $instance &
    done
    wait
}

miner()
{
    local CMD=$1
    local INSTANCES=$(grep -e "${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
    for instance in $INSTANCES
    do
        echo $instance
        bin/miner --rpcaddr $instance --command $CMD --threadnum 2 &
    done
    wait
}

get_coinbase()
{
    local NODES=( ${!1} )
    for node in ${NODES[@]}
    do
        coinbase=$(py/get_coinbase.py $node)
        echo "$node,$coinbase" >>$COINBASE_FILE
    done
}

######## MAIN ########

INDEX_NAME=${1:-ethereum}

# Copy files to be used by others
sudo cp $VM_IP_FILE node/genesis.json node/start_geth.sh node/start_geth_light.sh /var/www/html

# init geth on each node
NODES=( $(cat $VM_IP_FILE | cut -d',' -f1 | uniq) )
1>/dev/null 2>&1 run_command "sudo -i rm genesis.json" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i wget http://conductor/genesis.json" NODES[@]
CMD='sudo -i geth init genesis.json'
run_command "$CMD" NODES[@]

# run geth on each node
1>/dev/null 2>&1 run_command "sudo -i rm start_geth.sh" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i wget http://conductor/start_geth.sh" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i chmod u+x start_geth.sh" NODES[@]
CMD='sudo -i at -f /root/start_geth.sh now + 1 minutes &'
run_command "$CMD" NODES[@]

# run another non-mining geth on attacker
NODES=( "attacker" )
CMD=$'sudo -i geth --datadir "/home/ubuntu/.ethereum" init /root/genesis.json'
run_command "$CMD" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i rm start_geth_light.sh" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i wget http://conductor/start_geth_light.sh" NODES[@]
1>/dev/null 2>&1 run_command "sudo -i chmod u+x start_geth_light.sh" NODES[@]
CMD='sudo -i at -f /root/start_geth_light.sh now + 1 minutes &'
run_command "$CMD" NODES[@]

sleep 2m

# Peering geth instances
echo "Connecting peers..."
NODES=( $(grep -v 'attacker' $VM_IP_FILE | cut -d',' -f1 | uniq) )
peer_nodes NODES[@] $BLOCKCHAIN_NET
add_peers NODES[@] 'attacker' $BLOCKCHAIN_NET
attacker_ip=$(grep -e "attacker,${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
victim_ip=$(grep -e "node5,${MGMT_NET}" $VM_IP_FILE | cut -d',' -f3)
listen_ip=$(grep -e "attacker,${BLOCKCHAIN_NET}" $VM_IP_FILE | cut -d',' -f3)
bin/add_peer --client "$victim_ip" --server "$attacker_ip:8555" --listener "$listen_ip:30304"

#echo "creating new accounts..."
#new_accounts
echo "Start mining..."
miner start
echo "Start stat collector..."
./start_stat_collector.sh $1

NODES=( $(cat $VM_IP_FILE | cut -d',' -f1 | uniq) )
get_coinbase NODES[@]

