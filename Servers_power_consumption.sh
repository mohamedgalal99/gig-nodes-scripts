#!/bin/bash
# Title          : power_sen.sh
# Description    : Collect power consumption for list of servers
# Author         : Mohamed Galal
# Example        :# bash power_sen.sh
# Note			 : you should place file called ( servers ) with format ( server_ip,server_user,server_password )

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ "${ip}" =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]
    then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]] && stat=0
    fi
    return $stat
}



function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ "${ip}" =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]
    then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]] && stat=0
    fi
    return $stat
}


[[ -f "servers" ]] || { echo "[-] Can't find servers file"; exit 1; }
[[ -f "server_power.log" ]] || touch server_power.log
for i in $(cat servers)
do
    server_ip="$(echo "${i}" | awk -F',' '{print $1}')"
    server_user="$(echo "${i}" | awk -F',' '{print $2}')"
    server_password="$(echo "${i}" | awk -F',' '{print $3}')"
    valid_ip "${server_ip}"
    x=$?
    [[ $x != 0 ]] && { echo "[-] server ip is wronge formated: ${server_ip}"; continue; }

    echo "[*] Server ${server_ip}" | tee -a server_power.log
    echo -ne "\t"
    echo $(ipmitool -I lanplus -H "${server_ip}" -U "${server_user}" -P ${server_password} sensor get Power1 Power2 | grep 'Sensor Reading' || echo "[-] Can't connect to Server ${server_ip}") | tee -a server_power.log
done
