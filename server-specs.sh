#/bin/bash
#title           :server_specs.sh
#description     :This script used to get some of server specs cpu model, number od cores and harddisks type and size
#author          :Mohamed Galal

cpu_num=$(lscpu  | grep -e "^CPU(s):" | awk '{print $2}')
cpu_model=$(lscpu  | grep -E "^Model\ name:" | awk -F: '{print $NF}' | sed 's/  //g')
mem_total=$(free -h | grep "Mem" | awk '{print $2}')
ssd=0
hdd=0
nvme=0

for i in $(lsblk | grep -E "^sd|^nvme" | awk '{print $1}')
do
    #[[ -f "/sys/block/${i}/queue/rotational" ]] || { echo "disk ${i} not found"; exit 1 }
    val=$(cat /sys/block/${i}/queue/rotational)
    if [[ ${i} =~ "nvme" ]]
    then
        (( nvme = nvme + 1 ))
    elif [[ ${val} == 0 ]]
    then
        (( ssd = ssd + 1 ))
    else
        (( hdd = hdd +1 ))
    fi
done

for i in $(lsblk | grep -E "^sd|^nvme" | awk '{print $4}' | sort | uniq )
do
    num=$(lsblk | grep -E "^sd|^nvme" | awk '{print $1, $4}' | grep ${i} | wc -l)
    if [[ ${nvme} = ${num} ]]
    then
        nvme="${i} * ${num}"
    elif [[ ${ssd} = ${num} ]]
    then
        ssd="${i} * ${num}"
    elif [[ ${hdd} = ${num} ]]
    then
        hdd="${i} * ${num}"
    fi
done
#echo -e "$(hostname)\t${cpu_model}\t${cpu_num}\t${mem_total}\t${ssd}\t${hdd}\t${nvme}"
#printf "%-40s %-50s %-8s %-8s %-10s %-10s %-10s\n" "$(hostname)" "${cpu_model}" "${cpu_num}" "${mem_total}" "${ssd}" "${hdd}" "${nvme}"
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$(hostname)" "${cpu_model}" "${cpu_num}" "${mem_total}" "${ssd}" "${hdd}" "${nvme}"
