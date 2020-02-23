#!/bin/bash

LOG_FILE=run.log

######## MAIN ########
cd /home/ubuntu/blockchain-network-security/scripts

DURATION=${1:-120}
# Build Environment
UNIXTIME=$(date +%s)
INDEX_NAME=$(date --date="@$UNIXTIME" +%Y%m%d-%H%M)_$DURATION
echo "$UNIXTIME,$INDEX_NAME,$DURATION" >>$LOG_FILE
./build_env.sh $INDEX_NAME
sleep 3m

# Perform the balance attack
./bgp-attack.sh $DURATION

sleep 2m

# Unbuild Environment
./unbuild_env.sh

