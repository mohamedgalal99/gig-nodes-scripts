#!/bin/bash
# Running on controller
docpath=
enviroment="be-g8-1"
JS="7.1.6"
AYS="7.1.6"
OVC="2.1.6"
ctrl_ip="10.101.106.254"
gw="10.101.0.1"
start_ip="10.101.106.10"
end="10.101.106.200"
netmask="255.255.0.0"
gid="1002"
pubvlan="101"
ityoukey="liX186LBIQeUENGxF0Ur_hAPSq1-S1NgHfuIXyyZoSoVoJ25fXN7"

[[ -f "/opt/g8-pxeboot/pxeboot/conf/hosts" ]] && echo "[*] Found hosts file" || { echo "[-] Can't find hosts file"; exit 1; }
nodes=($(cat /opt/g8-pxeboot/pxeboot/conf/hosts  | grep -Ev "^#|^$" | grep -E " cp[ua]-.*$| stor-.*$" | awk '{print $1}'))
nodes_names=($(cat /opt/g8-pxeboot/pxeboot/conf/hosts  | grep -Ev "^#|^$" | grep -E " cp[ua]-.*$| stor-.*$" | awk '{print $NF}'))  #get output as array

function check_docker ()
{
    docker_path=$(which docker)
    if [[ ${docker_path} ]]
    then
      echo "[+] found docker"
      docpath=${docker_path}
    else
      echo [-] docker not installed
      exit 1
    fi
}

function con ()
{
  comma=$1
  messa=$2
  echo -n "${messa} [y] : "
  read ans
  if [[ ${ans} == 'y' ]]
  then
    $comma
  fi
}

function send_ssh_command ()
{
  [[ ${#@} != 2 ]] && { echo "[-] send_ssh_command function take only two args"; exit 1; }
  ip=$1
  comma=$2
  echo $ip
  echo $comma
  ssh -A -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" root@${ip} "${comma}"
}

function start_httpfs ()
{
  [[ -f "/opt/g8-pxeboot/pxeboot/images/httpfs" ]] && echo "[+] Find httpfs file" || { "[-] Can't find /opt/g8-pxeboot/pxeboot/images/httpfs"; exit 1; }
  if [[ $(ps aux |grep -E "httpfs 8080$") ]]; then
    echo "[+] httpfs running on port 8080"
  else
    [[ $(tmux ls | grep "httpfs") ]] && tmux kill-session -t "httpfs"
    [[ $(netstat -nplt | awk '{print $4}' | grep ":8080$") ]] && { echo "[-] can't start httpfs, other service listen on 8080"; exit 1; }
    echo "[*] Starting httpfs on port 8080" 
    tmux new-session -s "httpfs" -d "cd /opt/g8-pxeboot/pxeboot/images; ./httpfs 8080"
  fi
}

function send_command_all_tmux ()
{
  #[[ ${#@} -eq "1" ]] && { echo "[-] Function send command take only one arg :("; exit 1; }
  comm=$1
  for (( i = 0; i < ${#nodes[@]}; i++ )); do
    nc -zv ${nodes[$i]} 22 &> /dev/null
    if [[ $? ]]
    then
      echo "[*] Sending command to ${nodes_names[${i}]} ..."
      tmux send-key -t connect_nodes_master:${nodes_names[${i}]} "${@}" ENTER
    else
      echo "[-] Can't ssh for ${nodes[${i}]} port 22 "
    fi
  done
}

function docker_config ()
{
  [[ -f "/etc/systemd/system/docker.service" ]] || { echo "[-] can't find docker.services file"; exit 1; }
  path="/etc/systemd/system/docker.service"
  sed -ie 's@^ExecStart=/usr/bin/dockerd.*$@ExecStart=/usr/bin/dockerd  -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --iptables=false --ip-masq=false@' ${path}
  containers=$(docker ps --format "{{.Names}}")
  echo "[+] Stopping Running dockers"
  echo ${containers} | xargs -n 1 docker stop
  systemctl daemon-reload || { echo "[-] Can't reload systemctl daemon"; exit 1; }
  systemctl restart docker.socket || { echo "[-] Can't restart docker socket"; exit 1; }
  systemctl restart docker.service || { echo "[-] Can't restart docker service"; exit 1; }
  echo "[+] start stopped dockers"
  echo ${containers} | xargs -n 1 docker start
} 

function check_services ()
{
  [[ $(ps aux |grep -E "httpfs 8080$") ]] && echo "[+] httpfs running on port 8080" || { echo "[-] httpfs not running"; start_httpfs; }
  [[ $(ps aux | grep -E "docker.\S" | grep " tcp://0.0.0.0:2375 ") ]] && echo "[+] dockerd running and listen on port 2375" || { echo "[-] dockerd not running or listen on port 2375"; docker_config; }
  [[ $(ssh-add -l) ]] && echo "[+] SSH key loaded" || { echo "[-] SSH key not loaded"; exit 1; }
}

function clean_repo ()
{
  if [[ ${#@} -ne "1" ]]
  then
    echo "[-] function clean_repo take only one arg, repo name"
    exit 1
  fi
  enviroment=$1
  cd /tmp
  [[ -d "env_${enviroment}" ]] && rm -rf "env_${enviroment}"
  git clone git@github.com:gig-projects/env_${enviroment}.git
  cd env_${enviroment}
  now=$(date +%y%m%d)
  git checkout -B "delete@${now}"
  git push --set-upstream origin delete@${now}
  git checkout master
  git reset --hard "$(git rev-list --max-parents=0 HEAD)"
  git push -f
  cd /tmp
  rm -rf env_${enviroment}
}

function docker_ip ()
{
  doc_name=${1}
  if [[ ${#@} -eq 1 ]]
  then
    doc_ip=$(docker inspect ${doc_name} | grep IPAdd | grep -v -E 'null,$|"",$' | awk -F: '{print $2}' | sed -E 's/"|\ |,//g' | uniq)
    echo ${doc_ip}
  else
    echo "[Error] Function docker_ip get only 1 arg => docker name"
    exit 1
  fi
}

function remove_image ()
{
  img=$1
  if [[ $(${docpath} images | grep "${img}") ]]; then
    echo "[+] Deleteing ${img} image"
    ${docpath} images | grep "${img}" | awk "{print $3}" | xargs -n 1 ${docpath} rmi
    #dockerID = $(${docpath} images | grep "${img}" | awk "{print $3}")
    #${docpath} rmi -f ${dockerID}
  else
    echo "[-] image not found"
    return 1
  fi
}

function remove_images_openvcloud_none ()
{
  if [[ $(${docpath} images | grep -E '^openvcloud/') ]]
  then
    images=$(${docpath} images | grep -E '^openvcloud/' | awk '{print $3}')
    echo ${images} | xargs -n 1 ${docpath} rmi -f               #modify at first run
  fi
  while [[ $(${docpath} images | grep -i 'none') ]]             #because of alot of none images generated
  do
    images=$(${docpath} images | grep -i 'none' | awk '{print $3}')
    echo ${images} | xargs -n 1 ${docpath} rmi -f               #modify at first run
  done
}

function remove_ovc_dockers ()
{
  if [[ $(${docpath} ps -a | egrep "ovcproxy|ovcreflector|ovcmaster|ovcgit") ]]
  then
    ovce_containers=$(docker ps | egrep "ovcproxy|ovcreflector|ovcmaster|ovcgit" | awk '{print $NF}')   #NF grep last column
    #ovce_containers=$(${docpath} ps --format "{{.Names}}" | egrep "ovcproxy|ovcreflector|ovcmaster|ovcgit")  #other method to upper line
    echo "[*] Found ovce containers, ${ovce_containers}"
    echo "[*] Stopping containers"
    echo ${ovce_containers} | xargs -n 1 ${docpath} stop       #modify at first run
    echo "[*] Removing containers"
    echo ${ovce_containers} | xargs -n 1 ${docpath} rm -f      #modify at first run
    [[ $(docker ps | egrep "ovcproxy|ovcreflector|ovcmaster|ovcgit") ]] && { echo "[Error] Some containesr not deleted"; exit 6; }
    ${docpath} ps -a --format '{{.Names}}'| grep -Ev 'pxeboot|jumpscale' | xargs -n 1 docker rm -f
  else
    echo "[*] No ovc containers found, environment is clean :)"
  fi
  remove_images_openvcloud_none
}

function git_docker ()
{
  [[ $(${docpath} ps --format "{{.Names}}" | grep "ovcgit") ]] && echo "[+] ovcgit docker is Running" || { echo "[-] ovcgit docker not running, some erorr happen"; exit 6; }
  git_ip=$(docker_ip ovcgit)
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${git_ip}
  sleep 4
  echo "[*] Enter ovcgit docker ssh Password:"
  ssh-copy-id root@${git_ip}
  send_ssh_command "${git_ip}" "cd /tmp && [[ -f 'git_node.sh' ]] && rm git-node.sh"
  send_ssh_command "${git_ip}" "cd /tmp && wget https://raw.githubusercontent.com/mohamedgalal99/gig-nodes-scripts/master/install-env-base_docker_new/git_node.sh"
  send_ssh_command "${git_ip}" "cd /tmp && /bin/bash git_node.sh -o \"${OVC}\" -l \"${enviroment}\" -gw \"${gw}\" -s \"${start_ip}\" -e \"${end}\" -n \"${netmask}\" -gid \"${gid}\" -iou \"${ityoukey}\""
  echo "[+] git docker Function finished"
}

function jumpscale_docker ()
{
  #[[ $(${docpath} ps | grep -E "jumpscale$") ]] && ${docpath} stop jumpscale    #be devil and delete it :D :D
  if [[ -d "/opt/master_var" ]]; then
    echo "[+] Removing containt of /opt/master_var"
    rm -rf /opt/master_var/*
  else
    echo '[+] creating /opt/master_var'
    mkdir -p /opt/master_var
    chown gig:gig /opt/master_var
    chmod 775 /opt/master_var
  fi

  if [[ $(docker ps --format "{{.Names}}" | grep "jumpscale") ]]
  then
    echo "[+] Jumpscale docker is installed and running"
    js_ip=$(docker_ip jumpscale)
    echo ${js_ip}
    echo '[+] Enter Password for Jumpscale container'
    comm="cd /tmp; [[ -f 'jumpscale_docker.sh' ]] && rm jumpscale_docker.sh;ls && sleep 3; wget https://raw.githubusercontent.com/mohamedgalal99/gig-reinstall-nodes/master/base_docker_new/jumpscale_docker.sh"
    #ssh -A root@${js_ip} ${comm}
    #echo -e "Host 172.17.0.\n\tStrictHostKeyChecking no" > ~/.ssh/config
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R ${js_ip}
    ssh-copy-id root@${js_ip}
    send_ssh_command "${js_ip}" "echo -e \"Host github.com\n\tStrictHostKeyChecking no\" > ~/.ssh/config"
    send_ssh_command "${js_ip}" "cd /tmp && { [[ -f 'jumpscale_docker.sh' ]] && rm jumpscale_docker.sh; }"
    send_ssh_command "${js_ip}" "cd /tmp && wget https://raw.githubusercontent.com/mohamedgalal99/gig-reinstall-nodes/master/base_docker_new/jumpscale_docker.sh"
    echo "[[ OoO ]] ${enviroment}"
    send_ssh_command "${js_ip}" "cd /tmp && /bin/bash jumpscale_docker.sh -j ${JS} -a ${AYS} -o ${OVC} -e ${enviroment} -c ${ctrl_ip} "
    sleep 8
    #con "git_docker" "[*] Installing ovcmaster, ovcproxy and configure them" ##Function git_docker ()
  elif [[ $(${docpath} ps -a --format "{{.Names}}" | grep "jumpscale") ]]
  then
    echo "[+] found Jumpscale docker installed but stopped"
    echo "[+] removing Jumpscale docker "
    ${docpath} rm -f "jumpscale" || { echo "[-] Faild to remove jumpscale docker"; exit 7; }
    echo "[+] Remove jumpscale image"
    remove_image "jumpscale/ubuntu1404"     ## function remove_image ()
    echo "[+] Installing Jumpscale image"
    ${docpath} pull "jumpscale/ubuntu1404" || { echo "[-] can't find jumpscale docker image"; exit 7; }
    ${docpath} run -d --name="jumpscale" "jumpscale/ubuntu1404" || { echo "[-] can't start jumpscale container"; exit 7; }
    sleep 5
    jumpscale_docker
  else
    echo "[+] Installing Jumpscale image"
    ${docpath} pull "jumpscale/ubuntu1404" || { echo "[-] can't find jumpscale docker image"; exit 7; }
    ${docpath} run -d --name="jumpscale" "jumpscale/ubuntu1404" || { echo "[-] can't start jumpscale container"; exit 7; }
    sleep 5
    jumpscale_docker
  fi
}

function nodes_to_git ()
{
  echo -n "[Oo] Enter password to ssh for nodes: "
  read -s pw
  echo -e "\n"
  if [[ ${nodes} && ${nodes_names} ]]
  then
    [[ "${#nodes[@]}" -ne "${#nodes_names[@]}" ]] && { echo "[-] Nodes and ips not same length."; exit 1; }
    [[ $(tmux ls | grep -E "^connect_nodes_master" | awk '{print $1}' | sed -e 's/:$//') ]] && tmux kill-session -t connect_nodes_master
    tmux new-session -s connect_nodes_master -d
    for (( i = 0; i < ${#nodes[@]}; i++ ))
    do
      tmux new-window -t connect_nodes_master -n ${nodes_names[${i}]} "ssh -A -o \"UserKnownHostsFile=/dev/null\" -o \"StrictHostKeyChecking=no\" root@${nodes[${i}]}"
      echo "[*] Connecting to ${nodes_names[${i}]} ... "
    done
    sleep 5
    tmux kill-window -t connect_nodes_master:0
    send_command_all_tmux "${pw}"
    send_command_all_tmux "cd /tmp ; [[ -f 'nodes_connect_git.sh' ]] && rm 'nodes_connect_git.sh'"
    sleep 5
    send_command_all_tmux "cd /tmp; wget https://raw.githubusercontent.com/mohamedgalal99/gig-reinstall-nodes/master/base_docker_new/nodes_connect_git.sh && { bash nodes_connect_git.sh -j ${JS} -a ${AYS} -o ${OVC} -e ${enviroment} && exit; }"
  else
    echo "[-] No node found in hosts file"
  fi
  while [[ $(tmux ls | grep -E "^connect_nodes_master" | awk '{print $1}' | sed -e 's/:$//') ]]
  do
    echo -en "*"
    sleep 2
  done
  echo -e "\n"      
}

#[[ -d "/var/master_var" ]] && { echo "[+] Removing containt under /opt/master_var"; rm -rf /opt/master_var; }
#echo "[*] Check Docker Installed"
#check_docker
con "check_docker" "[*] Check Docker Installed"

#echo "[*] Check Services httpfs && docker listen on specific port"
#check_services
con "check_services" "[*] Check Services httpfs && docker listen on specific port"

#echo "[*] Remove ovc_dockers ovcgit ovcproxy ovcmaster ovsreflector"
#remove_ovc_dockers
con "remove_ovc_dockers" "[*] Remove ovc_dockers ovcgit ovcproxy ovcmaster ovsreflector"

#echo "[*] Clean github repo env_du-conv-3 "
#clean_repo "du-conv-3"
con "clean_repo ${enviroment}" "[*] Clean github repo ${enviroment}"

#echo "[*] clean Jumpscale docker and install required packages on it"
#jumpscale_docker
[[ $(${docpath} ps | grep -E "jumpscale$") ]] && ${docpath} stop jumpscale
con "jumpscale_docker" "[*] clean Jumpscale docker and install required packages on it"

#login to ovcgit to execute
con "git_docker" "[*] Installing ovcmaster, ovcproxy and configure them" ##Function git_docker ()

#login to all nodes to execute
#con "nodes_to_git" " [*] Connect nodes to ovcgit"
