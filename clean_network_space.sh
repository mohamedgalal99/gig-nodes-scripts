#!/bin/bash

#############################
# This SCript used to clean #
# unused penVswitch bridges #
#############################

export LC_ALL=${LANG}
declare -a used_network

for i in $(virsh list --all --name)	#get all vms on node
do
  network=$(virsh dumpxml ${i} | grep -E "<source network='space_....'" | awk -F"'" '{print $2}')  #which ovs bridge vm attached to
  used_network+=(${network})
  #echo ${network}
done

for i in $(ovs-vsctl list-br | grep -E "^space_....") # get all space bridges
do
  if [[ ! ${used_network[@]} =~ ${i} ]]; then # check this bridge not in use
    echo ${i}
    for port in $(ovs-vsctl list-ports ${i}) # get ports to delete (not required)
    do
      ovs-vsctl del-port ${i} ${port} && echo "[+] Port ${i} deleted" || echo "[-] Can't delete Port ${i}"
    done
    ovs-vsctl del-br ${i} && echo "[+] Bridge ${i} deleted" || echo "[-] Can't delete Bridge ${i}"
  fi
done
