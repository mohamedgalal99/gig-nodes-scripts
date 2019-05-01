#!/bin/bash

function print ()
{
    red="\033[1;31m"
    green="\033[1;32m"
    yellow="\033[1;33m"
    blue="\033[1;34m"
    reset="\033[0m"

    state=$1
    message=$2
    if [[ "${state}" == "ok" || "${state}" = "+" ]]
    then
        echo -en "${green}[${state^^}] ${reset}${message}\n"
    elif [[ "${state}" == "err" ]]
    then
        echo -en "${red}[ERROR] ${reset}${message}\n"
    elif [[ "${state}" == "info" ]]
    then
        echo -en "${blue}[INFO] ${reset}${message}\n"
    else
        echo -en "$1\n"
    fi
}

dir="/etc/test"
[[ -d "/etc/test" ]] && print "+" "we find dir ${dir}" || print "err" "we can't find this ${dir}"

dir="/etc"
[[ -d "/etc" ]] && print "+" "we find dir ${dir}" || print "err" "we can't find this ${dir}"
