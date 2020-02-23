#!/bin/bash

VM_SPEC_FILE="vm.json"
VM_IP_FILE="ip.csv"
COINBASE_FILE="coinbase.csv"
MGMT_NET="InternetAccess"
BLOCKCHAIN_NET="private"
ES_INDEX_NAME="ethereum"
STAT_POLL_INTERVAL="1"

NOVA_URL="http://controller-pub:8774/v2.1/"
GLANCE_URL="http://controller-pub:9292"
OS_AUTH_URL="http://controller-pub:5000/v3/"
OS_IMAGE_API_VERSION="2"
OS_COMPUTE_API_VERSION="2.1"
OS_PROJECT_DOMAIN_NAME="default"
OS_USER_DOMAIN_NAME="default"
OS_PROJECT_NAME="BlockchainNetworkSecurity"
OS_USERNAME="parinya"
OS_PASSWORD="pwd4openstack"

