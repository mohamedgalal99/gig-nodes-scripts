# This script used to change vm boot && cloud-init disks to other disks migrated from other env

# Running on stor node
import JumpScale.portal
from JumpScale import j
from CloudscalerLibcloud import openvstorage

new_vm_id=395   # vm id in new env
old_vm_id=214   # vm id in old env (we migrate to new env)
old_vm_passwd='Nho4xq2pG'   # old vm passwd
boot_storage_node='10.1.1.21'       #grep from vm xml
#virsh dumpxml vm-401 | grep -A1 bootdisk-vm-${new_vm_id} | sed -e 's#^\ *##' | grep -e '^<host .*>$' | awk -F"'" '{print $2}'
cloud_init_storage_node='10.1.3.23' #grep from vm xml
#virsh dumpxml vm-401 | grep -A1 cloud-init-vm-${new_vm_id} | sed -e 's#^\ *##' | grep -e '^<host .*>$' | awk -F"'" '{print $2}'

#qemu-img convert -p -f raw -O raw ./bootdisk-vm-${old_vm_id}.qcow2 openvstorage+tcp:${boot_storage_node}:26203/vm-${new_vm_id}/bootdisk-vm-${old_vm_id}
#qemu-img convert -p -f raw -O raw ./cloud-init-vm-${old_vm_id}.qcow2 openvstorage+tcp:${boot_storage_node}:26203/vm-${new_vm_id}/cloud-init-vm-${old_vm_id}

cl = j.clients.osis.getNamespace('cloudbroker')
lcl = j.clients.osis.getNamespace('libcloud')
vm = cl.vmachine.get(new_vm_id)
vm_disk = vm.disks[0]
disk = cl.disk.get(vm_disk)

vdisk_bootdisk_new = openvstorage.getVDisk('/mnt/vmstor/vm-%s/bootdisk-vm-%s.raw' % (new_vm_id, new_vm_id))     # to get disk guid
vdisk_cloudinit_new = openvstorage.getVDisk('/mnt/vmstor/vm-%s/cloud-init-vm-%s.raw' % (new_vm_id, new_vm_id))  # to get disk guid

vdisk_bootdisk_old = openvstorage.getVDisk('/mnt/vmstor/vm-%s/bootdisk-vm-%s.raw' % (new_vm_id, old_vm_id))     # to get disk guid
vdisk_cloudinit_old = openvstorage.getVDisk('/mnt/vmstor/vm-%s/cloud-init-vm-%s.raw' % (new_vm_id, old_vm_id))  # to get disk guid

disk.refrenceId = 'openvstorage+tcp://%s:26203/vm-%s/bootdisk-vm-%s.raw@%s' % (boot_storage_node, old_vm_id, new_vm_id, vdisk_bootdisk_old.guid)
cl.disk.set(disk)

xml = lcl.libvirtdomain.get('domain_%s' % vm.referenceId)

xml = xml.replace(vdisk_bootdisk_new.guid, vdisk_bootdisk_old.guid).replace(vdisk_cloudinit_new.guid, vdisk_cloudinit_old.guid)
xml = xml.replace('bootdisk-vm-%s' % new_vm_id,'bootdisk-vm-%s' % old_vm_id).replace('cloud-init-vm-%s' % new_vm_id,'cloud-init-vm-%s' % old_vm_id)
lcl.libvirtdomain.set(xml, 'domain_%s' % vm.referenceId)

vm.accounts[0].password = old_vm_passwd
cl.vmachine.set(vm)
