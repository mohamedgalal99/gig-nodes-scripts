#!/bin/bash
baseTFTP="/opt/g8-pxeboot/pxeboot/tftpboot/pxelinux.cfg"
baseIP="/opt/g8-pxeboot/pxeboot/conf"

#check if base files exist
function check {
  [ -f "$baseIP/hosts" ] || { echo [-] "can't find $baseIP/hosts file" && exit 1; }
  [ -f "$baseIP/dhcphosts" ] || { echo [-] "can't find $baseIP/dhcphosts file" && exit 1; }
  [ -f "$baseTFTP/911boot" ] || { echo [-] "can't find $baseTFTP/911boot file" && exit 1; }
}

function enable_pxe {
  [ $# -gt 1 ] && { echo "[-] This function take only one arg, NODE NAME" && exit; }
  [ $1 ] && node=$1 || { echo "[-] please enter target node" && exit 4; }
  cd $baseIP
  mac=01-`cat dhcphosts | awk 'BEGIN {FS=",";OFS=","}; {if ($2 == "'$node'" ) print $1}' | tr ":" "-"`
  cd $baseTFTP
  [ -L $mac ] && echo "[*] Allready found link of $node" || ( ln -s 911boot $mac && echo "[+] Link created for $node" || { echo [Error] faild to create to $node && exit 5; })
}

#reboot_from_pxe cpu-01
function reboot_from_pxe {
  [ $# -qt 1 ] && { echo "[-] This function take only one arg, NODE NAME" && exit; }
  [ $1 ] && node="ipmi-"$1 || { echo "[-] please enter target node" && exit; }
  cd $baseIP && ip=`grep "\s$node" $baseIP/hosts | awk '{print $1}'`
  if [[ $node == *"cpu"* ]]
  then
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis bootdev pxe > /dev/null && echo "[*] Set $node to boot from pxe" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  elif [[ $node == *"stor"* ]]; then
    ipmitool -I lanplus -H $ip -U admin -P admin chassis bootdev pxe > /dev/null && echo "[*] Set $node to boot from pxe" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U admin -P admin chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  fi
}

#reboot_from_hd cpu-01
function reboot_from_hd {
  [ $# -qt 1 ] && { echo "[-] This function take only one arg, NODE NAME" && exit; }
  [ $1 ] && node="ipmi-"$1 || { echo "[-] please enter target node" && exit; }
  cd $baseIP && ip=`grep "\s$node" $baseIP/hosts | awk '{print $1}'`
  if [[ $node == *"cpu"* ]]
  then
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis bootdev hard > /dev/null && echo "[*] Set $node to boot from hard disk" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  elif [[ $node == *"stor"* ]]; then
    ipmitool -I lanplus -H $ip -U admin -P admin chassis bootdev hard > /dev/null && echo "[*] Set $node to boot from hard disk" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U admin -P admin chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  fi
}

#reboot_node cpu-01 pxe
#reboot_node stor-01 hd
function reboot_node {
  [ $# -qt 2 ] && echo "[-] This function take 2 args, NODE NAME, pxe||hd" && exit
  [ $1 ] && node="ipmi-"$1 || ( echo "[-] please enter target node" && exit )
  ( [ $2 == 'pxe' ] || [ $2 == 'hd' ] ) && boot=$2 || ( echo "[-]Please enter from where u want node to boot, pxe or hard disk 'hd'" && exit)
  cd $baseIP && ip=`grep "\s$node" $baseIP/hosts | awk '{print $1}'`
  if [[ $node == *"cpu"* ]]
  then
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis bootdev $boot > /dev/null && echo "[*] Set $node to boot from $boot" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U ADMIN -P ADMIN chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  elif [[ $node == *"stor"* ]]; then
    ipmitool -I lanplus -H $ip -U admin -P admin chassis bootdev $boot > /dev/null && echo "[*] Set $node to boot from $boot" || { echo "[Error] faild to make $node boot from pxe" && break; }
    ipmitool -I lanplus -H $ip -U admin -P admin chassis power cycle > /dev/null && echo "[*] Restarting $node " || (echo "[Error] faild to power cycle $node")
  fi
}

#installer_node cpu-01 password
function installer_node {
  [[ $# != "1" ]] && echo "[-] This function take only one arg, NODE NAME" && exit
  node=$1
  cd $baseIP && ip=`grep "\s$node" $baseIP/hosts | awk '{print $1}'`
  canConnect=0
  counter=1
  echo "[*] Try to connect to $node"
  while [ $canConnect != 1 ]; do
    nc -z $ip 22 && { canConnect=1 && break; }|| { canConnect=0 && printf "."; }
    if [ $counter == "60" ]; then
      printf "[=>] $node doesn't come back yet, Do u want to retry connect to it other 1 min [y/n]: "
      read answer
      if [ $answer == "y" ]; then
        counter=0
        continue
      elif [ $answer == "n" ]; then\
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
}
