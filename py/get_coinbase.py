#!/usr/bin/python

import argparse
from ethjsonrpc import EthJsonRpc

ETH_PORT = 8545

def parseRpcAddr(rpcaddr):
    if rpcaddr.find(":") != -1:
        s = rpcaddr.split(":")
        netaddr = s[0]
        port = int(s[1])
    else:
        netaddr = rpcaddr
        port = ETH_PORT
    return (netaddr, port)

if __name__ == "__main__":
    # parse arguments
    parser = argparse.ArgumentParser(description='.')
    parser.add_argument("rpcaddr", help="RPC address of an ethereum node", default="127.0.0.1")
    args = parser.parse_args()
    
    netaddr, port = parseRpcAddr(args.rpcaddr)
    eth_client = EthJsonRpc(netaddr, port)
    coinbase = eth_client.eth_coinbase()

    print coinbase

