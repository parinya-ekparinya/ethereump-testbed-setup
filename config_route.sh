#!/bin/bash

source $PWD/env.py
source $PWD/setup_utils.sh

################ MAIN 

# Add routes on attacker
NODES=( "attacker" )
CMD='sudo route add -net 172.16.107.0/24 gw 172.16.101.26'
run_command "$CMD" NODES[@]
CMD='sudo route add -net 172.16.108.0/24 gw 172.16.101.26'
run_command "$CMD" NODES[@]

# Add routes on attacker subgroup
NODES=( $(grep -e "^node\d*[1234]" $VM_IP_FILE | cut -d',' -f1 | uniq) )
CMD='sudo route add -net 172.16.101.0/24 gw 172.16.107.29'
run_command "$CMD" NODES[@]
CMD='sudo route add -net 172.16.108.0/24 gw 172.16.107.29'
#run_command "$CMD" NODES[@]

# Add routes on victim subgroup
NODES=( $(grep -e "^node\d*[56789]" $VM_IP_FILE | cut -d',' -f1 | uniq) )
CMD='sudo route add -net 172.16.101.0/24 gw 172.16.108.22'
run_command "$CMD" NODES[@]
CMD='sudo route add -net 172.16.107.0/24 gw 172.16.108.22'
run_command "$CMD" NODES[@]

