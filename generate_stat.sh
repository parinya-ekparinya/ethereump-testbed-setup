#!/bin/bash

LOG_FILE=${1:-"run.log.tmp"}

######## MAIN ########
cd /home/ubuntu/blockchain-network-security/scripts

for run in $(cat $LOG_FILE)
do
    time=$(echo $run | cut -d',' -f1)
    index=$(echo $run | cut -d',' -f2)
    ./get_attack_stat.py localhost $index $time
done
