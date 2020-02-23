#!/usr/bin/python

import novaclient.client
from common import *
from env import *


if __name__ == "__main__":
    sess = get_session()
    nova = novaclient.client.Client(OS_COMPUTE_API_VERSION, session=sess)

    instances = get_vm_json()
    with open(VM_IP_FILE, "w") as out_file:
        for instance in instances:
            server = nova.servers.find(name=instance["name"])
            for net, ip in server.networks.iteritems():
                out_file.write("{},{},{}\n".format(server.name, net, ip[0]))

