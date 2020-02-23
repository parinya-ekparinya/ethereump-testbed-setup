#!/bin/bash

source env.py

config_hosts_file()
{
    cp /etc/hosts.orig /etc/hosts
    local HOSTNAME
    local IP
    local INSTANCES=$(grep -e "${MGMT_NET}" $VM_IP_FILE | cut -d',' -f1,3)
    for instance in $INSTANCES
    do
        HOSTNAME=$(echo $instance | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')
        IP=$(echo $instance | cut -d',' -f2)
        echo "$IP $HOSTNAME"
        echo "$IP $HOSTNAME" >>/etc/hosts
    done
}

######## MAIN ########
config_hosts_file

