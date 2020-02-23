#!/usr/bin/python

from datetime import datetime
from operator import itemgetter
import argparse
import json
import sys
import csv
import eth_elasticsearch
import env

if __name__ == "__main__":
    # parse arguments
    parser = argparse.ArgumentParser(description='Get total difficulty and the point of segmentation, and total difficulty on each side.')
    parser.add_argument("es_host", help="elasticsearch hostname or IP address")
    parser.add_argument("index", help="index name")
    parser.add_argument("time", help="timestamp when the run starts")
    args = parser.parse_args()
    eth_es = eth_elasticsearch.EthereumElasticsearch(args.es_host, args.index)
    duration = int(args.index.split("_")[1])
    ref_time = int(args.time)

    with open(env.COINBASE_FILE, mode="r") as infile:
        reader = csv.reader(infile)
        coinbases = dict((rows[0], rows[1]) for rows in reader)

    with open("bgp-attack.log", mode="r") as infile:
        event_log = list(csv.reader(infile))

    lines = [l for l in event_log if ref_time < int(l[0]) < (ref_time + duration + 360)]
    
    common_ancestor = eth_es.get_common_ancestor(int(args.time) + 330)
    designated_block = eth_es.get_common_offspring(int(common_ancestor["timestamp"]) + duration)
    diff_base = common_ancestor["totalDifficulty"]
    begin_time = int(common_ancestor["timestamp"])
    #end_time = int(designated_block["timestamp"])
    try:
        end_time = int(lines[3][0])
    except IndexError:
        sys.stderr.write("ERROR: %s\n" % lines)
        exit(1)

    blocks = eth_es.get_blocks_by_time_range(begin_time, end_time)
    even_node_coinbases = [coinbases[node] for node in coinbases.keys() if node[-1] in ["0", "2", "4", "6", "8"]]
    blocks_by_attacker = [b for b in blocks if b["miner"] == coinbases["attacker"]]
    blocks_by_odd = [b for b in blocks if b["miner"] not in even_node_coinbases]
    blocks_by_even = [b for b in blocks if b["miner"] in even_node_coinbases]

    blocks_by_odd = sorted(blocks_by_odd, key=itemgetter("totalDifficulty"), reverse=True)
    blocks_by_even = sorted(blocks_by_even, key=itemgetter("totalDifficulty"), reverse=True)
    head_odd = blocks_by_odd[0]
    head_even = blocks_by_even[0]
    diff_odd = head_odd["totalDifficulty"]
    diff_even = head_even["totalDifficulty"]

    def get_chain_by_head(block):
        if block["number"] <= 0:
            return [block]
        else:
            parent_chain = get_chain_by_head(eth_es.get_parent_block(block))
            if parent_chain:
                return parent_chain + [block]
            else:
                return parent_chain

    chain_odd = get_chain_by_head(head_odd)
    chain_even = get_chain_by_head(head_even)

    for b in chain_odd:
        print "odd,{},{},{}".format(b["timestamp"], b["number"], b["difficulty"])

    for b in chain_even:
        print "even,{},{},{}".format(b["timestamp"], b["number"], b["difficulty"])

