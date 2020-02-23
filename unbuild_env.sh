#!/bin/bash

source $PWD/env.py
source $PWD/setup_utils.sh

# stop stat_collector
sudo pkill stat_collector
# delete index in elasticsearch
1>/dev/null 2>&1 curl -X DELETE 'http://localhost:9200/ethereum'

rm $COINBASE_FILE

# kill geth instances and remove their database
NODES=( $(cat $VM_IP_FILE | cut -d',' -f1 | uniq) )
run_command 'sudo pkill geth' NODES[@]
run_command $'printf "y\\n" | sudo -i geth removedb' NODES[@]
NODES=( "attacker" )
run_command $'printf "y\\n" | sudo -i geth --datadir "/home/ubuntu/.ethereum" removedb' NODES[@]

