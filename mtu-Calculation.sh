#/bin/bash


[[ ${#@} -gt 7 ]] && { echo "[-] Alot of arguments provided"; exit 1; }
[[ ${#@} -lt 6 ]] && { echo "[-] Missing Arguments"; exit 1; }
succes=0
fail=0
silent=0
declare -i mtu_start
declare -i mtu_end
declare -x ip

function checks_arg ()
{
    ip_addr=$1
    start=$2
    end=$3
    quit=$4
    
    # Test if mtu start < end
    [[ ${start} -ge ${end} ]] && { [[ ${quit} -eq 0 ]] && echo "[ERROR] Start port can't be greater than End port"; exit 2; }

    # Test if i can ping ip
    ping -c1 -l 1 ${ip_addr} &> /dev/null
    [[ $? -ne 0 ]] && { [[ ${quit} -eq 0 ]] && echo "[ERROR] Can't reach this ${ip_addr} with normal ping"; exit 3; } 
}

while [[ true ]]
do
    case $1 in
        -i | --ip )
        ip=$2
        shift 2
          ;;
        -s | --mtu-start )
        mtu_start=$2
        shift 2
          ;;
        -e | --mtu-end )
        mtu_end=$2
        shift 2
          ;;
        -q | --quit )
        silent=1
        shift 1
          ;;
        -h | --help )
        echo "will write it soon"
          ;;
        -*)
        echo "[ERROR] Unkown Option Provided"
        exit 1
          ;;
        *)
        break
          ;;
    esac
done

checks_arg ${ip} ${mtu_start} ${mtu_end} ${silent}

# Start ping and count success and fail one without package frag
for (( i=${mtu_start}; i<=${mtu_end}; i++ ))
do
  ping -c 1 -M do -s ${i} ${ip} &> /dev/null
  [[ $? -eq 0 ]] && { succes=$(( ${succes} + 1 )); [[ ${silent} -eq 0 ]] && echo -n "| "; } || { fail=$(( ${fail} + 1 )); [[ ${silent} -eq 0 ]] && echo -n ". "; }
done

if [[ ${silent} -eq 0 ]]
then
    echo ""
    echo -e "[INFO] Low MTU: ${mtu_start}\tSucces: ${succes}\tFail: ${fail}"
    echo "[OK] Best MTU is: $(( ${mtu_start} + ${succes} - 1  ))"
else
    echo "$(( ${mtu_start} + ${succes} - 1  ))"
fi
