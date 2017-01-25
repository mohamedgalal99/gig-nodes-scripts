#!/bin/bash
#  02
# Run on Jumpscale docker
# bash jumpscale_docker.sh -j 7.1.6 -a 7.1.6 -o 2.1.6 -e du-conv-3 -c 192.168.27.0

enviroment=
JS=
AYS=
OVC=
ctrl_ip=
[[ ${#@} -gt 10 ]] && echo "[-] Alot of args provided" && exit 1
[[ ${#@} -lt 10 ]] && echo "[-] Missing args" && exit 1
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
    -c | --controller)
    ctrl_ip=$2
    shift 2
      ;;
    -h | --help )
    echo "[options]"
    echo "-j --JSBRANCH \t\t Jumpscale git branch"
    echo "-a --AYSBRANCH \t\t ays git branch"
    echo "-o --OVCBRANCH \t\t ovc git branch"
    echo "-e --enviroment \t\t Enviroment Name"
    echo "-c --controller \t\t Controller which dockers going to be installed on it"
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
[[ -d /opt ]] && rm -rf /opt/* || { echo "[-] /opt not found"; mkdir -v /opt; chmod 755 /opt; }
[[ -d /opt ]] && echo "[+] found dir /opt" || { echo "[-] can't create /opt"; exit 1; }

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

cd /tmp/openvcloud/scripts/install
[[ -f "01-scratch-openvloud.sh" ]] || { echo "[-] 01 file not found"; exit 1; }
echo ${JS}
sed -ie 's/^JSBRANCH=.*/JSBRANCH="'''${JS}'''"/' "01-scratch-openvloud.sh"
sed -ie 's/^AYSBRANCH=.*/AYSBRANCH="'''${AYS}'''"/' "01-scratch-openvloud.sh"
sed -ie 's/^OVCBRANCH=.*/OVCBRANCH="'''${OVC}'''"/' "01-scratch-openvloud.sh"
bash 01-scratch-openvloud.sh
sleep 10
jspython 02-scratch-init.py --environment du-conv-3 --backend docker --port 2375 --remote 172.17.0.1 --public ${ctrl_ip}

