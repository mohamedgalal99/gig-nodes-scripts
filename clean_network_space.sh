#!/bin/bash

export LC_ALL=${LANG}
declare -a used_network

for i in $(virsh list --all --name)
do
  network=$(virsh dumpxml ${i} | grep -E "<source network='space_....'" | awk -F"'" '{print $2}')
  used_network+=(${network})
  #echo ${network}
done

for i in $(ovs-vsctl list-br | grep -E "^space_....")
do
  if [[ ! ${used_network[@]} =~ ${i} ]]; then
    echo ${i}
    #ovs-vsctl del-br ${i} && echo "[+] Bridge ${i} deleted" || echo "[-] Can't delete Bridge ${i}"
  fi
done
