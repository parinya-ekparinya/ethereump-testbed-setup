#!/bin/bash

CONDUCTOR=172.16.100.22

install_pkg()
{
  apt-get -y install software-properties-common
  #add-apt-repository -y ppa:ethereum/ethereum
  apt-get update
  apt-get -y install rsh-client rsh-server lftp git dsniff
}

init_network()
{
  local IF_PREFIX=ens
  for num in 4
  do
    ip link | grep ${IF_PREFIX}$num 1>/dev/null
    if [ $? -eq 0 ]; then
      echo "
  auto ${IF_PREFIX}$num
  iface ${IF_PREFIX}$num inet dhcp" >>/etc/network/interfaces.d/50-cloud-init.cfg
      ifup ${IF_PREFIX}$num
    fi
  done
  echo "$CONDUCTOR conductor" >>/etc/hosts
  route add -net default gw 172.16.100.22
  echo "nameserver 8.8.4.4" >/etc/resolv.conf
}

config_rsh()
{
  RHOSTS=/home/ubuntu/.rhosts
  echo "+ +" >$RHOSTS
  chown ubuntu:ubuntu $RHOSTS
  chmod 600 $RHOSTS
}

init_geth()
{
  # install geth
  for f in abigen evm geth rlpdump swarm ; do
    wget http://conductor/$f
    chmod u+x $f
    mv $f /usr/bin/
  done

  # new account
  local PASSPHRASE="passphrase"
  printf "$PASSPHRASE\\n$PASSPHRASE\\n" | geth account new

  # make DAG file
  mkdir ~/.ethash
  geth makedag 360000 ~/.ethash
}

######## MAIN ########
init_network
install_pkg
config_rsh
init_geth

