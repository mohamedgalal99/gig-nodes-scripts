#!/bin/bash
#title           :fix-vm-raw-disk.sh
#description     :This script used to Fix VM boot raw disk
#author		 :Mohamed Galal
#git url         :https://raw.githubusercontent.com/mohamedgalal99/gig-nodes-scripts/master/fix-vm-raw-disk.sh 

[[ $# != 1 ]] && { echo "[*] This function take vm name ex: vm-123"; exit 1; }
vm="$1"

[[ -d "/mnt/vmstor/${vm}" ]] || { echo "Can't find dir for ${vm}"; exit 1; }
cd /mnt/vmstor/${vm}
[[ -f "bootdisk-${vm}.raw" ]] || { echo "Can't find boot disk for vm ${vm}"; exit 1; }

loop=$(losetup -f)
echo "[*] will use ${loop}"
losetup -P ${loop} bootdisk-${vm}.raw  #mount disk in loop with its pations
fdisk -l ${loop} | grep "Linux filesystem"
if [[ $? == 0 ]]; then
	device=$(fdisk -l /dev/loop0 | grep "Linux filesystem" | awk '{print $1}')
	echo "[+] Start check on device ${device}"
	fsck -y ${device}
	echo "[+] Removing loop device"
	losetup -d ${loop} || { echo "[-] Error happen while delete ${device}"; exit 1; }
else
	echo "[-] Can't find disk with type Linux filesystem"
	echo "[+] Removing loop device"
	losetup -d ${loop} || { echo "[-] Error happen while delete ${device}"; exit 1; }
	exit 1
fi

