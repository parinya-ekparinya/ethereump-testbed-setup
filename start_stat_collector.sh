#!/bin/bash

source env.py

if [ ! -z $1 ]; then
    ES_INDEX_NAME=$1
fi

curl -X PUT -H "Content-Type: application/json" "http://localhost:9200/$ES_INDEX_NAME"
curl -X PUT -H "Content-Type: application/json" "http://localhost:9200/$ES_INDEX_NAME/_mapping/block" -d @es/mapping_block.json
curl -X PUT -H "Content-Type: application/json" "http://localhost:9200/$ES_INDEX_NAME/_mapping/record" -d @es/mapping_record.json

# start stat collector for all nodes
ENTRIES=$(grep -e "$MGMT_NET" $VM_IP_FILE | cut -d',' -f3)
for entry in $ENTRIES
do
    nohup bin/stat_collector --rpcaddr $entry --index "$ES_INDEX_NAME" --interval $STAT_POLL_INTERVAL &
done

