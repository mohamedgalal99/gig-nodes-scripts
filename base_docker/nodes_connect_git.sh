#!/bin/bash

JS=7.1.6
AYS=7.1.6
OVC=2.1.6
enviroment="du-conv-3"

[[ $(ssh-add -l) ]] && echo "[+] ssh key loaded" || { echo "[-] ssh key not loaded"; exit 1; }
[[ -d /tmp ]] || { echo "[-] can't fine /tmp"; exit 0; }
if [[ -d "/tmp/openvcloud" ]]
then
  cd /tmp/openvcloud
  bran=$(git branch | awk '{print $2}')
  if [[ ${bran} != ${OVC} ]]
  then
    echo "[-] not same branch"
    cd /tmp
    rm -rf openvcloud
    ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts          #clone over ssh without check fingerprint
    git clone -b ${OVC} git@github.com:0-complexity/openvcloud.git
  fi
else
  git clone -b ${OVC} git@github.com:0-complexity/openvcloud.git
fi
[[ -f "/tmp/branch.sh" ]] && rm /tmp/branch.sh
touch /tmp/branch.sh
echo -e "export JSBRANCH=${JS}\nexport AYSBRANCH=${AYS}\nexport OVCBRANCH=${OVC}" > /tmp/branch.sh
[[ -f "/tmp/openvcloud/scripts/install/06-node-connect.sh" ]] || { echo "[-] Can't find 06 script"; exit 1; }
bash /tmp/openvcloud/scripts/install/06-node-connect.sh ${enviroment}.demo.greenitglobe.com || { echo "[-] error in connecting nodes to master"; exit 1; }

response=$?
press=""
echo -n "[*] Installation finished press any key to close session: "
read x
exit ${response}
