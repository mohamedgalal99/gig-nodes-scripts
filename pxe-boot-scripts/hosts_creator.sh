#/bin/bash
# This script used to create hosts file in pxeboot/config

file=$1
interface="zt3"
env="b17"

ip_suffix="$(ip -o a s ${interface} | head -1 | awk '{print $4}' | awk 'BEGIN {FS="."; OFS="."}{print $1,$2,$3}')"
nodes=($(cat "${file}" | awk '{print $1}'))
macs=($(cat "${file}" | awk '{print $2}'))
stor_count=1

for (( i = 0 ; i <= ${#nodes[@]}; i++ ))
do
	if [[ "${nodes[${i}]::-3}" == "cpu" ]]
	then
		if [[ ${i} -le 9 ]]
		then
			if [[ "${macs[${i}]}" == "00:00:00:00:00:00" ]]
			then
				echo "#${ip_suffix}.$(( ${i} + 11 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			else
				echo "${ip_suffix}.$(( ${i} + 11 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			fi
		else
			if [[ "${macs[${i}]}" == "00:00:00:00:00:00" ]]
			then
				echo "#${ip_suffix}.$(( ${i} + 11 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			else
				echo "${ip_suffix}.$(( ${i} + 11 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			fi
		fi
	elif [[ "${nodes[i]::-3}" == "stor" ]]
	then
		if [[ ${i} -le 9 ]]
		then
			if [[ "${macs[${i}]}" == "00:00:00:00:00:00" ]]
			then
				echo "#${ip_suffix}.$(( ${i} + 21 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			else
				echo "${ip_suffix}.$(( ${i} + 21 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			fi
		else
			if [[ "${macs[${i}]}" == "00:00:00:00:00:00" ]]
			then
				echo "#${ip_suffix}.$(( ${i} + 21 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			else
				echo "${ip_suffix}.$(( ${i} + 21 )) ${nodes[${i}]}.${env} ${nodes[${i}]}"
			fi
		fi
	fi
done
exit 0
