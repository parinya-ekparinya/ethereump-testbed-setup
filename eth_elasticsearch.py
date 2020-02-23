#!/usr/bin/python

from datetime import datetime
import argparse
import json
import sys
from elasticsearch import Elasticsearch


class EthereumElasticsearch(object):
    def __init__(self, es_host, index="ethereum"):
        self.es = Elasticsearch([{"host": es_host, "port": 9200}])
        self.index = index
    
    def get_block_by_hash(self, block_hash):
        res = self.es.search(index=self.index, body={
          "query": {
            "bool": {
              "filter": [
                {"type": {"value": "block"}}, 
                {"term": {"hash": block_hash}}
              ]
            }
          }
        })
        blocks = [b["_source"] for b in res["hits"]["hits"]]
        block = next(iter(blocks), None)
        return block
    
    def get_blocks_by_number(self, block_number):
        res = self.es.search(index=self.index, body={
          "query": {
            "bool": {
              "filter": [
                {"type": {"value": "block"}}, 
                {"term": {"number": block_number}}
              ]
            }
          }
        })
        blocks = [b["_source"] for b in res["hits"]["hits"]]
        return blocks
    
    def get_blocks_by_time_range(self, begin_time, end_time):
        res = self.es.search(index=self.index, body={
          "size": 10000,
          "query": {
            "bool": {
              "filter": [
                {"type": {"value": "block"}}, 
                {
                  "range": {
                    "timestamp": {
                      "gt": begin_time,
                      "lt": end_time
                    }
                  }
                }
              ]
            }
          }
        })
        blocks = [b["_source"] for b in res["hits"]["hits"]]
        return blocks
    
    def get_parent_block(self, block):
        return self.get_block_by_hash(block["parentHash"])

    def get_children_blocks(self, block):
        blocks = self.get_blocks_by_number(block["number"] + 1)
        children = [b for b in blocks if b["parentHash"] == block["hash"]]
        return children
    
    def get_ancestor_by_number(self, block, ancestor_number):
        if isinstance(ancestor_number, basestring) and ancestor_number.startswith("0x"):
            ancestor_number = int(ancestor_number, 0)
        if block["number"] <= ancestor_number:
            return block
        else:
            parent = self.get_block_by_hash(block["parentHash"])
            return self.get_ancestor_by_number(parent, ancestor_number)
    
    def get_records_by_time(self, ref_time="now"):
        filter_aggs_name = "at_time"
        bucket_aggs_name = "group_by_serverAddress"
        top_hits_aggs_name = "records"

        res = self.es.search(index=self.index, body={
          "size": 0,
          "aggs": {
            filter_aggs_name: {
              "filter": {
                "bool": {
                  "must": {
                    "range": {
                      "timestamp": {
                        "lte": ref_time
                      }
                    }
                  }
                }
              },
              "aggs": {
                bucket_aggs_name: {
                  "terms": {
                    "field": "serverAddress"
                  },
                  "aggs": {
                    top_hits_aggs_name: {
                      "top_hits": {
                        "sort": [
                          {"timestamp": {"order" : "desc"}}
                        ],
                        "size": 1,
                      }
                    }
                  }
                }
              }
            }
          }
        })
        #print json.dumps(res, indent=4, sort_keys=True)
        buckets = res["aggregations"][filter_aggs_name][bucket_aggs_name]["buckets"]
        # Get records and sort them by latest block number descendingly
        records = [bucket[top_hits_aggs_name]["hits"]["hits"][0]["_source"] for bucket in buckets]
        return records

    def get_common_ancestor(self, ref_time="now"):
        records = self.get_records_by_time(ref_time)
        # Sort records by latest block number descendingly
        records.sort(key=lambda (rec): rec["blockNumber"], reverse=True)
        min_block_number = records[-1]["blockNumber"]
        
        # Travese the tree upward to the same height
        for record in records:
            block_hash = record["blockHash"]
            block = self.get_block_by_hash(block_hash)
            record["ancestor"] = self.get_ancestor_by_number(block, min_block_number)
        # Find the most recent common ancestor
        while True:
            ancestors = [n["ancestor"] for n in records]
            if ancestors.count(ancestors[0]) == len(ancestors):
                break
            for record in records:
                record["ancestor"] = self.get_parent_block(record["ancestor"])
        return records[0]["ancestor"]

    def get_common_offspring(self, ref_time):
        while True:
            records = self.get_records_by_time(ref_time)
            records.sort(key=lambda (rec): rec["blockNumber"], reverse=True)
            hashes = [r["blockHash"] for r in records]
            if hashes.count(hashes[0]) == len(hashes):
                break
            ref_time += 1
        return self.get_block_by_hash(hashes[0])

    def get_blocks_by_txn(self, txn):
        res = self.es.search(index=self.index, body={
          "query": {
            "bool": {
              "filter": [
                {"nested": {
                  "path": "transactions",
                  "query": {
                    "bool": {
                      "filter": [
                        {"term": {"transactions.hash": txn}}
                      ]
                    }
                  }
                }},
                {"type": {"value": "block"}}
              ]
            }
          }
        })
        blocks = [hit["_source"] for hit in res["hits"]["hits"]]
        blocks.sort(key=lambda (block): block["number"], reverse=True)
        return blocks

    def get_blocks_by_miner(self, miner):
        res = self.es.search(index=self.index, body={
          "sort": [
            {"timestamp": {"order" : "desc"}}
          ],
          "size": 10,
          "query": {
            "bool": {
              "filter": [
                {"term": {"miner": miner}},
                {"type": {"value": "block"}}
              ]
            }
          }
        })
        blocks = [hit["_source"] for hit in res["hits"]["hits"]]
        blocks.sort(key=lambda (block): block["timestamp"], reverse=True)
        return blocks

    def get_blocks_by_uncle(self, uncle):
        res = self.es.search(index=self.index, body={
          "sort": [
            {"timestamp": {"order" : "desc"}}
          ],
          "size": 10,
          "query": {
            "bool": {
              "filter": [
                {"term": {"uncle": uncle}},
                {"type": {"value": "block"}}
              ]
            }
          }
        })
        blocks = [hit["_source"] for hit in res["hits"]["hits"]]
        blocks.sort(key=lambda (block): block["timestamp"], reverse=True)
        return blocks

if __name__ == "__main__":
    pass

