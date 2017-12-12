#!/bin/bash
##03
#git node
#ssh root@172.17.0.1 -p 2202 -A

# bash git_node.sh -o 2.1.6 -e "du-conv-3" -gw "192.168.24.1" -s "192.168.27.100" -e "192.168.27.200" -n "255.255.248.0" -gid "666" -iou "Du62VVc0MTB6AxEOnjw5SUH2K4wXdXIauK4lze9dBzOi-FtYEXen"
#bash git_node.sh -o "${OVC}" -e "${location}" -gw "${gw}" -s "${start_ip}" -e "${end}" -n "${netmask}" -gid "${gid}" -iou "${ityoukey}"

OVC=
gw=
start_ip=
end=
netmask=
gid=
ityoukey=
location=

[[ ${#@} -gt 16 ]] && echo "[-] Alot of args provided" && exit 1
[[ ${#@} -lt 16 ]] && echo "[-] Missing args" && exit 1
while [[ $1 ]]; do
  case $1 in
    -gw | --gateway )
    gw=$2
    shift 2
      ;;
    -s | --start )
    start_ip=$2
    shift 2
      ;;
    -e | --end )
    end=$2
    shift 2
      ;;
    -n | --netmask )
    netmask=$2
    shift 2
      ;;
    -gid | --gridId )
    gid=$2
    shift 2
      ;;
    -iou | --itsyouonline )
    ityoukey=$2
    shift 2
      ;;
    -l | --location )
    location=$2
    shift 2
      ;;
    -o | --OVCBRANCH )
    OVC=$2
    shift 2
      ;;
    -h | --help )
    echo "[options]"
    echo "-l --location \t\t location name"
    echo "-gid --gridId \t\t Enviroment grid Id"
    echo "-iou --itsyouonline \t\t itsyou.online deployment key"
    echo "-gw --gateway \t\t Enviroment gateway"
    echo "-n --netmask \t\t IP netmask ex: 255.255.255.0"
    echo "-s --start \t\t Satrting ip"
    echo "-e --end \t\t Ending ip"
    echo "-o --OVCBRANCH \t\t ovc git branch"
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
#Jumpscale container
#[[ ${JS} =~ [1-9]\.[1-9]\.[1-9] || ${JS} =~ [1-9]\.[1-9] || ${JS} = 'master' ]] || { "[-] Unknown JS branch"; exit 1; }
#[[ ${AYS} =~ [1-9]\.[1-9]\.[1-9] || ${AYS} =~ [1-9]\.[1-9] || ${AYS} = 'master' ]] || { "[-] Unknown AYS branch"; exit 1; }
[[ ${OVC} =~ [1-9]\.[1-9]\.[1-9] || ${OVC} =~ [1-9]\.[1-9] || ${OVC} = 'master' || ${OVC} = 'production' ]] || { "[-] Unknown OVC branch"; exit 1; }
[[ $(ssh-add -l) ]] && echo "[+] ssh key loaded" || { echo "[-] SSH key not found"; exit 1; }

if [[ -d "/tmp/openvcloud" ]]
then
  cd /tmp/openvcloud
  bran=$(git branch | awk '{print $2}')
  if [[ ${bran} != ${OVC} ]]
  then
    echo "[-] not same branch"
    cd /tmp
    rm -rf openvcloud
    git clone -b ${OVC} git@github.com:0-complexity/openvcloud.git
  fi
else
  git clone -b ${OVC} git@github.com:0-complexity/openvcloud.git
fi
echo "[=-=-=-=-=-=-=-=-=--] env_${location}" 
cd /opt/code/github/gig-projects/env_${location}
[[ -f "/tmp/openvcloud/scripts/install/03-ovcgit-master-spawn.py" ]] || { echo "[-] Can't find 03-ovcgit-master-spawn.py script"; exit 1; }
jspython /tmp/openvcloud/scripts/install/03-ovcgit-master-spawn.py -R || { echo "[-] Error in running 03 spawn script"; exit 1; }
[[ -f "/tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py" ]] || { echo "[-] Can't find 04-ovcgit-master-configure.py script"; exit 1; }
jspython /tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py -g ${gw} --start ${start_ip} --end ${end} --netmask ${netmask} --gid ${gid} --ssl wildcard -c greenitglobe.environments.${location} -cs ${ityoukey} || { sleep 10; jspython /tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py -g ${gw} --start ${start_ip} --end ${end} --netmask ${netmask} --gid ${gid} --ssl wildcard -c greenitglobe.environments.${location} -cs ${ityoukey}; }
