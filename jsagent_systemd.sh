#!/bin/bash

f="/opt/jumpscale7/hrd/apps/jumpscale__jsagent__main/service.hrd"
ays stop -n jsagent
if [[ -f "${f}" ]]
then
  echo "[+] Found file ${f}"
else
  echo "[-] Can't find file ${f}"
  ays start -n jsagent
  exit 1
fi

sed -i 's#jspython#/usr/local/bin/jspython#' ${f}
sed -i 's#tmux#upstart#' ${f}
ays start -n jsagent
systemctl status jsagent_main
