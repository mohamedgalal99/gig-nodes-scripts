# jspython delete_destroyed_cs.py

import JumpScale.portal
from JumpScale import j
from time import sleep

wait=1
cll = j.clients.osis.getNamespace('cloudbroker')
cloudspacess = ccl.cloudspace.search({'status': 'DESTROYED'}, size=0)
for i in xrange (1,cloudspacess[0]):
    id = cloudspacess[i].get('guid')
    print ('[+] Deleting Cloudspace id: %s' % id)
    #ccl.cloudspace.delete(id)
    if wait > 5:
        sleep(2)
        wait=1
    else:
        try:
            ccl.cloudspace.delete(id)
        except Exception as e:
            print ('Cant delete cloudspace id: %s' % id)
    wait+=1
