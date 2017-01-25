#!/bin/bash
##04
# Execute on nodes
#bash nodes_connect_git.sh -j 7.1.6 -a 7.1.6 -o 2.1.6 -e "du-conv-3"

JS=
AYS=
OVC=
enviroment=

[[ ${#@} -gt 8 ]] && echo "[-] Alot of args provided" && exit 1
[[ ${#@} -lt 8 ]] && echo "[-] Missing args" && exit 1
while [[ true ]]; do
  case $1 in
    -j | --JSBRANCH )
    JS=$2
    shift 2
      ;;
    -a | --AYSBRANCH )
    AYS=$2
    shift 2
      ;;
    -o | --OVCBRANCH )
    OVC=$2
    shift 2
      ;;
    -e | --enviroment)
    enviroment=$2
    shift 2
      ;;
    -h | --help )
    echo "[options]"
    echo "-j --JSBRANCH \t\t Jumpscale git branch"
    echo "-a --AYSBRANCH \t\t ays git branch"
    echo "-o --OVCBRANCH \t\t ovc git branch"
    echo "-e --enviroment \t\t Enviroment Name"
    exit 0
      ;;
    -*)
    echo "[Error] Unknow option, give '-h' for help"
    exit 1
      ;;
    *)
    break
      ;;
  esac
done

[[ $(ssh-add -l) ]] && echo "[+] ssh key loaded" || { echo "[-] ssh key not loaded"; exit 1; }
[[ -d /tmp ]] || { echo "[-] can't fine /tmp"; exit 1; }

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

