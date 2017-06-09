from JumpScale import j
import libvirt

'''
This Script used to start vms , were running on other node, on new node
Need to be run on node where we want to start vms on it
It will start all vms which not marked as destroyed in DB
This script working only for vms , not ROS
Note: don't run it if other node is alive, this make vms conflict, and mak sure when old node come back to undefine vms
'''

## to change later
stopped_stack=6
move_to_node=7    ## remove , gong to run it on specific node

## From ovc code
def action(networkid):
    from CloudscalerLibcloud.utils.libvirtutil import LibvirtUtil
    connection = LibvirtUtil()
    networks = connection.connection.listNetworks()
    from JumpScale.lib import ovsnetconfig
    vxnet = j.system.ovsnetconfig.ensureVXNet(networkid, 'vxbackend')
    bridgename = vxnet.bridge.name
    networkinformation = {'networkname': bridgename}
    if bridgename not in networks:
        #create the bridge if it does not exist
        connection.createNetwork(bridgename, bridgename)
    return networkinformation


cl = j.clients.osis.getNamespace('cloudbroker')
libcl = j.clients.osis.getNamespace("libcloud")

location = cl.location.get(1).name
old_node = cl.stack.get(stopped_stack).name
new_node = cl.stack.get(move_to_node).name

print ("\t[*] do u want to start vms on dead node %s on other node %s" % (old_node, new_node))  # make q with answer

vms = cl.vmachine.search({"stackId": stopped_stack, "status": {"$ne": "DESTROYED"}}, size=0)
node_uri = cl.stack.get(move_to_node).apiUrl

for i in xrange (1,vms[0]+1):
    refrence_id = vms[i].get('referenceId')    ## refrence id to get xml file from mongo
    xml = libcl.libvirtdomain.get("domain_%s" % refrence_id)
    nid = cl.cloudspace.get(vms[i].get('cloudspaceId')).networkId
    action(nid)
    try:
        c = libvirt.open("qemu:///system")
        c.defineXML(xml)
        try:
            dom = c.lookupByName(vms[i].get("hostName"))
            dom.create()
            vm = cl.vmachine.get(vms[i].get('guid'))
            vm.stackId = move_to_node
            cl.vmachine.set(vm)
        except Exception as e:
            print e
    except Exception as e:
        print e

    # print libcl.libvirtdomain.get('domain_%s' % refrence_id)
    #print (vm.name)
