#!/bin/bash

echo "[*] Get Nodes MAC ..."
baseTFTP="/opt/g8-pxeboot/pxeboot/tftpboot/pxelinux.cfg"
baseIP="/opt/g8-pxeboot/pxeboot/conf"
enviromentName="be-g8-3"
installerPasswd="ENTER PAWWORD"
apt-get install -y sshpass
#declare -A arrMAC       #To declare array

##
#create pxe links for cpu nodes and stor nodes
##
nodes=(`cat dhcphosts | awk 'BEGIN {FS=",";OFS=" "}; {if ($2 ~ "^ipmi-cpu" || $2 ~ "^ipmi-stor" ) print $2}'`)
for node in ${nodes[@]}
do
    mac=`cat dhcphosts | awk 'BEGIN {FS=",";OFS=","}; {if ($2 == "'$node'" ) print $1}' | tr ":" "-"`
    #arrMAC[$node]=$mac
    cd $baseTFTP
    [ -L $mac ] && echo "[*] Allready found link of $node" || ( ln -s 911boot $mac && echo "[+] Link created for $node" || (echo [Error] faild to create to $node && exit ))
    cd $baseIP
done

##
# Restart nodes to boot from pxe
##
for node in ${nodes[@]}
do
  ip=`grep "$node" $baseIP/hosts | awk '{print $1}'`
  if [[ $node == *"cpu"* ]]
  then
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis bootdev pxe > /dev/null && echo "[*] Set $node to boot from pxe" || (echo "[Error] faild to make $node boot from pxe" && break)
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  elif [[ $node == *"stor"* ]]; then
    ipmitool -I lanplus -H $ip -U admin -P admin chassis bootdev pxe > /dev/null && echo "[*] Set $node to boot from pxe" || (echo "[Error] faild to make $node boot from pxe" && break)
    ipmitool -I lanplus -H $ip -U admin -P admin chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  fi
done


##
# Restart nodes to boot from hard
##
for node in ${nodes[@]}
do
  ip=`grep "$node" $baseIP/hosts | awk '{print $1}'`
  if [[ $node == *"cpu"* ]]
  then
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis bootdev hard > /dev/null && echo "[*] Set $node to boot from hard disk" || (echo "[Error] faild to make $node boot from pxe" && break)
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  elif [[ $node == *"stor"* ]]; then
    ipmitool -I lanplus -H $ip -U admin -P admin chassis bootdev hard > /dev/null && echo "[*] Set $node to boot from hard disk" || (echo "[Error] faild to make $node boot from pxe" && break)
    ipmitool -I lanplus -H $ip -U admin -P admin chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  fi
done


##
#login to installer nodes
##
canConnect=0
counter=1
for node in ${nodes[@]}
do
  canConnect=0
  ip=`grep "$node" $baseIP/hosts | awk '{print $1}'`
  echo "[*] Try to connect to $node"
  while [ $canConnect != 1 ]; do
    nc -z $ip 22 && ( canConnect=1 && break )|| ( canConnect=0 && printf "." )
    if [ $counter == "60" ]; then
      printf "[=>] $node doesn't come back yet, Do u want to retry connect to it other 1 min [y/n]: "
      read answer
      if [ $answer == "y" ]; then
        #statements
        counter=0
        continue
      elif [ $answer == "n" ]; then
        #statements
        break
      fi
    fi
    ((counter++))
    sleep 1
  done
  if [ $canConnect == "0" ]; then
    break
  fi
  sshpass -p$installerPasswd ssh -o StrictHostKeyChecking=no root@$ip 'cd /root/tools && bash Install "'$enviromentName'"'
done
