#!/bin/bash

S=$1
R=$2
#S_COINBASE=$(./get_coinbase.py $S)
#R_COINBASE=$(./get_coinbase.py $R)
S_COINBASE=$3
R_COINBASE=$4
BALANCE=$5

tx='{"from": "'"$S_COINBASE"'", "to": "'"$R_COINBASE"'", "value":"0x'"$BALANCE"'"}'
data='{"jsonrpc":"2.0", "method":"personal_sendTransaction", "params":['"$tx"', "passphrase"],"id":42}'
result=$( curl -X POST --header "Content-Type:application/json" --data "$data" $S )
echo $tx >>tmp.log
echo "$data" >>tmp.log
echo "$result" >>tmp.log
result=${result##*result\":\"}
result=${result%%\"*}
echo "$result"

