#/bin/bash

file=$1

echo -e "# Nodes\n"
nodes=($(cat "${file}" | awk '{print $1}'))
macs=($(cat "${file}" | awk '{print $2}'))

for (( i = 0; i < ${#nodes[@]}; i++ ))
do
        if [[ "${macs[${i}]}" != "00:00:00:00:00:00" ]]
        then
                echo "${macs[${i}]},${nodes[${i}]},infinite"
        else
                echo "${macs[${i}]},${nodes[${i}]},infinite #dont"
        fi
done

echo -e "\n# IPMI\n"

ipmi_macs=($(cat "${file}" | awk '{print $3}'))
for (( i = 0; i < ${#nodes[@]}; i++ ))
do
        echo "${ipmi_macs[${i}]},ipmi-${nodes[${i}]},infinite"
        if [[ "${ipmi_macs[${i}]}" != "00:00:00:00:00:00" ]]
        then
                echo "${ipmi_macs[${i}]},ipmi-${nodes[${i}]},infinite"
        else
                echo "${ipmi_macs[${i}]},ipmi-${nodes[${i}]},infinite #dont"
        fi
done
