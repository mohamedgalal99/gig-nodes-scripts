#!/bin/bash
#git node
#ssh root@172.17.0.1 -p 2202 -A

# bash git_docker1.sh -j 7.1.6 -a 7.1.6 -o 2.1.6
enviroment="du-conv-3"
JS=
AYS=
OVC=
gw="192.168.24.1"
start="192.168.27.100"
end="192.168.27.200"
netmask="255.255.248.0"
gid="666"
ityoukey="Du62VVc0MTB6AxEOnjw5SUH2K4wXdXIauK4lze9dBzOi-FtYEXen"

[[ ${#@} -gt 6 ]] && echo "[-] Alot of args provided" && exit 1
[[ ${#@} -lt 6 ]] && echo "[-] Missing args" && exit 1
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
    -h | --help )
    echo "[options]"
    echo "-j --JSBRANCH \t\t Jumpscale git branch"
    echo "-a --AYSBRANCH \t\t ays git branch"
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
[[ ${JS} =~ [1-9]\.[1-9]\.[1-9] || ${JS} =~ [1-9]\.[1-9] || ${JS} = 'master' ]] || { "[-] Unknown JS branch"; exit 1; }
[[ ${AYS} =~ [1-9]\.[1-9]\.[1-9] || ${AYS} =~ [1-9]\.[1-9] || ${AYS} = 'master' ]] || { "[-] Unknown AYS branch"; exit 1; }
[[ ${OVC} =~ [1-9]\.[1-9]\.[1-9] || ${OVC} =~ [1-9]\.[1-9] || ${OVC} = 'master' ]] || { "[-] Unknown OVC branch"; exit 1; }
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
cd /opt/code/github/gig-projects/env_${enviroment}
[[ -f "/tmp/openvcloud/scripts/install/03-ovcgit-master-spawn.py" ]] || { echo "[-] Can't find 03-ovcgit-master-spawn.py script"; exit 1; }
jspython /tmp/openvcloud/scripts/install/03-ovcgit-master-spawn.py -R || { echo "[-] Error in running 03 spawn script"; exit 1; }
[[ -f "/tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py" ]] || { echo "[-] Can't find 04-ovcgit-master-configure.py script"; exit 1; }
jspython /tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py -g ${gw} --start ${start} --end ${end} --netmask ${netmask} --gid ${gid} --ssl wildcard -c greenitglobe.environments.${enviroment} -cs ${ityoukey} || { sleep 10; jspython /tmp/openvcloud/scripts/install/04-ovcgit-master-configure.py -g ${gw} --start ${start} --end ${end} --netmask ${netmask} --gid ${gid} --ssl wildcard -c greenitglobe.environments.${enviroment} -cs ${ityoukey}; }
