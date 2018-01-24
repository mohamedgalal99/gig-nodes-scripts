#!/bin/bash

[[ -d "/lib/systemd/system" ]] || { echo "[-] Can't find this dir /lib/systemd/system"; exit 1; }
cd /lib/systemd/system
for i in $(ls | grep scrub)
do
  scrub="$(grep "ExecStart=" ${i} | awk '{print $4}' | awk -F? '{print $1}' | sed 's#arakoon://config##')"
  ovs config get ${scrub} > /tmp/test
  [ -s "/tmp/test" ]
  if [[ $? != 0 ]]; then
    echo "[+] Removing scrub ..."
    rm -rf /lib/systemd/system/${i}
  else
    echo "[-] Can't remove this scrub ${i}, They r in use :D"
  fi
done
