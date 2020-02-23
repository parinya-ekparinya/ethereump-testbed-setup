#!/usr/bin/python

import time
import novaclient.client
from common import *
from env import *


if __name__ == "__main__":
    sess = get_session()
    nova = novaclient.client.Client(OS_COMPUTE_API_VERSION, session=sess)

    instances = get_vm_json()
    for instance in instances:
        try:
            server = nova.servers.find(name=instance["name"])
        except novaclient.exceptions.NotFound:
            continue
        server.delete()
        print instance["name"]
        time.sleep(0.25)

