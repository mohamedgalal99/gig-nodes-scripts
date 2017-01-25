#!/bin/bash
# Running on controller
docpath=
JS="7.1.6"
AYS="7.1.6"
OVC="2.1.6"


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

function check_services ()
{
  [[ $(ps aux |grep -E "httpfs 8080$") ]] && echo "[+] httpfs running on port 8080" || { echo "[-] httpfs not running"; exit 1; }
  [[ $(ps aux | grep "dockerd " | grep " tcp://0.0.0.0:2375 ") ]] && echo "[+] dockerd running and listen on port 2375" || { echo "[-] dockerd not running or listen on port 2375"; exit 1; }
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
    doc_ip=$(docker inspect ${doc_name} | grep IPAdd | grep -v -E 'null,$|"",$' | awk -F: '{print $2}' | sed -E 's/"|\ |,//g')
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
    dockerID = $(${docpath} images | grep "${img}" | awk "{print $3}")
    ${docpath} rmi -f ${dockerID}
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
    [[ $(docker ps | egrep "ovcproxy|ovcreflector|ovcmaster|ovcgit") ]] && { echo "[Error] Some containesr not deleted"; exit 1; }
  else
    echo "[*] No ovc containers found, environment is clean :)"
  fi
  remove_images_openvcloud_none
}

function jumpscale_docker ()
{
  [[ $(${docpath} ps | grep -E "jumpscale$") ]] && ${docpath} stop jumpscale    #be devil and delete it :D :D
  if [[ $(docker ps --format "{{.Names}}" | grep jumpscale) ]]
  then
    echo "[+] Jumpscale docker is installed and running"
    js_ip=$(docker_ip jumpscale)
    echo $js_ip
    echo '[+] Password for Jumpscale container'
    comm="cd /tmp && wget https://raw.githubusercontent.com/mohamedgalal99/gig-reinstall-nodes/master/base_docker/jumpscale_docker.sh && bash jumpscale_docker.sh -j ${JS} -a ${AYS} -o ${OVC} && echo '[:)] Finished'"
    ssh -A root@${js_ip} ${comm}
  else
    if [[ $(docker ps --format "{.Names}" | grep jumpscale) ]]; then
      echo "[+] found Jumpscale docker installed but stopped"
      echo "[+] removing Jumpscale docker "
      ${docpath} rm jumpscale || { echo "[-] Faild to remove jumpscale docker"; exit 1; }
      echo "[+] Remove jumpscale image"
      remove_image "jumpscale/ubuntu1404"
      echo "[+] Installing Jumpscale image"
      ${docpath} pull jumpscale/ubuntu1404 || { echo "[-] can't find jumpscale docker image"; exit 1; }
      ${docpath} run -d --name=jumpscale jumpscale/ubuntu1404 || echo "[-] can't start jumpscale container"; exit 1;
      sleep 5
      jumpscale_docker
    fi
  fi
}

fuction con ()
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

[[ -d "/var/master_var" ]] && { echo "[+] Removing containt under /opt/master_var"; rm -rf /opt/master_var; }
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
con "clean_repo du-conv-3" "[*] Clean github repo env_du-conv-3"

#echo "[*] clean Jumpscale docker and install required packages on it"
#jumpscale_docker
con "jumpscale_docker" "[*] clean Jumpscale docker and install required packages on it"
