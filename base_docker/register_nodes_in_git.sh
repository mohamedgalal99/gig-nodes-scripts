#!/bin/bash
## connect to nodes

[[ -f "/opt/g8-pxeboot/pxeboot/conf/hosts" ]] && echo "[*] Found hosts file" || { echo "[-] Can't find hosts file"; exit 1; }
nodes=($(cat /opt/g8-pxeboot/pxeboot/conf/hosts  | grep -Ev "^#|^$" | grep -E " cp[ua]-..$| stor-..$" | awk '{print $1}'))
nodes_names=($(cat /opt/g8-pxeboot/pxeboot/conf/hosts  | grep -Ev "^#|^$" | grep -E " cp[ua]-..$| stor-..$" | awk '{print $NF}'))  #get output as array

echo -n "[Oo] Enter password to ssh for nodes: "
read -s pw
echo -e "\n"

function send_command ()
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

if [[ ${nodes} && ${nodes_names} ]]
then
  [[ "${#nodes[@]}" -ne "${#nodes_names[@]}" ]] && { echo "[-] Nodes and ips not same length."; exit 1; }
  [[ $(tmux ls | grep -E "^connect_nodes_master" | awk '{print $1}' | sed -e 's/:$//') ]] && tmux kill-session -t connect_nodes_master
  tmux new-session -s connect_nodes_master -d
  for (( i = 0; i < ${#nodes[@]}; i++ )); do
    #statements
    tmux new-window -t connect_nodes_master -n ${nodes_names[${i}]} "ssh -A -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" root@${nodes[${i}]}"
    echo "[*] Connecting to ${nodes_names[${i}]} ... "
  done
  sleep 5
  tmux kill-window -t connect_nodes_master:0
  send_command "${pw}"
  send_command "cd /tmp ; [[ -f 'nodes_connect_git.sh' ]] && rm 'nodes_connect_git.sh'"
  sleep 5
  send_command "cd /tmp; wget https://raw.githubusercontent.com/mohamedgalal99/gig-reinstall-nodes/master/base_docker/nodes_connect_git.sh && { bash nodes_connect_git.sh && exit; }"
else
  echo "[-] No node found in hosts file"
fi


#while [[ $(tmux ls | grep -E "^connect_nodes_master" | awk '{print $1}' | sed -e 's/:$//') ]]
#do
#  echo -en "*"
#  sleep 2
#done
#echo -e "\n"
