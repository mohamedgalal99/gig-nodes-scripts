#!/bin/bash

docpath=

function check_docker ()
{
    docker_path=$(which docker)
    if [[ ${docker_path} ]]
    then
      echo "[*] found docker"
      docpath=${docker_path}
    else
      echo [-] docker not installed
      exit 1
    fi
}

function docker_ip ()
{
  if [[ $@ -eq 1 ]]; then
    doc_name=$1
    doc_ip=$(docker inspect ${doc_name} | grep IPAdd | grep -v -m1 'null,$' | awk -F : '{print $2}' | sed -E 's/"|\ |,//g') &> /dev/null | { echo " [Error] Can't find this container ${doc_name} && exit 1;"
    echo ${doc_ip}
  else
    echo "[Error] Function docker_ip get only 1 arg => docker name"
    exit 1
  fi
}

function container_running_check()     # check if docker container exist and running, ex: pxeboot and jumpscale7 containers
{
  [[ ${#@} -eq 1 ]] || {echo "[Error] Only one arg (container name) provide for func container_running_check"; exit 1;}
  container=$1
  [[ $(docker ps -a | grep ${container}) ]] || {echo "[Error] Can't find this container :( "; exit 1;}
  status=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep ${container} | awk '{print $2}')
  if [[ ${status} == "Up" ]]; then
    return 0
  else
    return 1
  fi
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
    echo "[*] No ovce containesr found, environment is clean :)"
    exit 1
  fi
}

function remove_images ()
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
