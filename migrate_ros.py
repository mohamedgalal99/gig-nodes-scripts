import libvirt
import jinja2
from JumpScale import j

def create_vm(xml_config):
    try:
        conn = libvirt.open()
        dom = conn.defineXML(xml_config)
        dom.create()
    except Exception as e:
        print e

def createROSNetwork(networkid, vlan):
    try:
        createnetwork = j.clients.redisworker.getJumpscriptFromName('greenitglobe', 'createnetwork')
        createnetwork.executeLocal(networkid=networkid)
        create_external_network = j.clients.redisworker.getJumpscriptFromName('greenitglobe', 'create_external_network')
        create_external_network.executeLocal(vlan=vlan)
    except Exception as e:
        print e
    
    
def createROS(network_id):
    vfwl = j.clients.osis.getNamespace('vfw')
    cl = j.clients.osis.getNamespace('cloudbroker')
    acl = j.clients.agentcontroller.get()
    
    grid_id = j.application.whoAmI.gid
    stack_ref = j.application.whoAmI.nid

    network_id_hex = "%04x" % (network_id)
    
    ros = vfwl.virtualfirewall.get("%s_%s" % (grid_id, network_id))
    ros.nid = stack_ref
    vfwl.virtualfirewall.set(ros)

    device_name = 'routeros/{0}/routeros-small-{0}'.format(network_id_hex)
    edge_ip, edge_port, edge_transport = acl.execute('greenitglobe', 'getedgeconnection', role='storagedriver', gid=grid_id)
    img_dir = j.system.fs.joinPaths(j.dirs.baseDir, 'apps/routeros/template/')
    try:
        xml_temp = jinja2.Template(j.system.fs.fileGetContents(j.system.fs.joinPaths(img_dir,'routeros-template.xml')))
        xml_source = xml_temp.render(networkid=network_id_hex, name=device_name, edgehost=edge_ip, edgeport=edge_port, edgetransport=edge_transport, publicbridge="public")
        createROSNetwork(network_id, ros.vlan)
        create_vm(xml_source)
    except Exception as e:
        print (e) 

def getROSDeployed(node_id):
    cl = j.clients.osis.getNamespace('cloudbroker')
    vfwl = j.clients.osis.getNamespace('vfw')

    ross = vfwl.virtualfirewall.search({'nid': int(cl.stack.get(node_id).referenceId)}, size=0)
    for i in xrange (1, ross[0]+1):
        net_id = ross[i].get('id')
        createROS(net_id)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--nodeid', type=int)
    options = parser.parse_args()
    getROSDeployed(options.nodeid)
