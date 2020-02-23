#!/bin/sh

SERVER_IP=$(ip addr show dev ens3 | grep -e 'inet\s' | awk '{print $2}' | cut -d'/' -f1)
NETWORKID=303

nohup geth --datadir "/home/ubuntu/.ethereum" --keystore "/root/.ethereum/keystore" \
    --networkid $NETWORKID --fast --rpc --rpcaddr $SERVER_IP --rpcport 8555 \
    --rpcapi eth,shh,web3,admin,debug,miner,personal,txpool \
    --nodiscover --port 30304 \
    1>/home/ubuntu/geth.out 2>&1 &

sleep 1s

