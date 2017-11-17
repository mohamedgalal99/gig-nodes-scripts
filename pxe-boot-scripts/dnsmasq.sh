#/bin/bash

env='b17'
nic="zt3"

ip_suffix="$(ip -o a s ${nic} | head -1 | awk '{print $4}' | awk 'BEGIN {FS="."; OFS="."}{print $1,$2,$3}')"

printf "domain=${env}\nexpand-hosts\nlocal=/${env}/\n\ninterface=eth0\n\n"
printf "bind-interfaces\ndhcp-range=lan,${ip_suffix}.0,static\ndhcp-option=lan,3,${ip_suffix}.1\ndhcp-option=lan,6,${ip_suffix}.240,8.8.8.8\naddn-hosts=/conf/hosts\nserver=8.8.8.8\nserver=8.8.4.4\n\n"
printf "enable-tftp\ndhcp-boot=pxelinux.0\ntftp-root=/tftpboot"
