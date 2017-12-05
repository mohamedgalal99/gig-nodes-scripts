#!/bin/bash

ovc_ver="2.1.7"
js_ver="7.1.7"
update="n"

base_dir="/opt/code/github/"

if [[ -d "${base_dir}/0-complexity" ]]
then
  cp -r ${base_dir}/0-complexity ~
  echo "[+] switching to ${base_dir}/0-complexity"
  cd ${base_dir}/0-complexity
  for i in $(ls | grep -v openvstorage-monitoring)
  do
    cd ${base_dir}/0-complexity/${i} && echo "[+] change to dir ${base_dir}/0-complexity/${i}"
    git status
    if [[ ${update} == "y" ]]
    then
      ver=$(git branch | grep "*" | awk '{print $2}')
      if [[ "${ovc_ver}" == "${ver}" ]]; then
        git pull
      else
        git checkout ${ovc_ver}
      fi
    fi
  done
else
  echo "[-] Can't find dir ${base_dir}/0-complexity"
fi

if [[ -d "${base_dir}/jumpscale7" ]]
then
  cp -r ${base_dir}/jumpscale7 ~
  echo "[+] switching to ${base_dir}/jumpscale7"
  cd ${base_dir}/jumpscale7
  for i in $(ls)
  do
    cd ${base_dir}/jumpscale7/${i} && echo "[+] change to dir ${base_dir}/jumpscale7/${i}"
    git status
    if [[ ${update} == "y" ]]
    then
      ver=$(git branch | grep "*" | awk '{print $2}')
      if [[ "${js_ver}" == "${ver}" ]]; then
        git pull
      else
        git checkout ${js_ver}
      fi
    fi
  done
else
  echo "[-] Can't find dir ${base_dir}/jumpscale7"
fi

for i in $(ays status | grep -E "^jumpscale|^openvcloud" | grep -v mongodb | awk '{print $2}')
do
  ays stop -n ${i}
done
