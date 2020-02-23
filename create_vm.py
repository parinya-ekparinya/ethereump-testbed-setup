#!/usr/bin/python

import time
import novaclient.client
import glanceclient.client
import neutronclient.v2_0.client
from common import *
from env import *


def create_vm(sess, kwargs):
    nova = novaclient.client.Client(OS_COMPUTE_API_VERSION, session=sess)
    glance = glanceclient.client.Client(OS_IMAGE_API_VERSION, session=sess)
    neutron = neutronclient.v2_0.client.Client(session=sess)
    image = glance.images.get(kwargs["image"])
    flavor = nova.flavors.find(name=kwargs["flavor"])
    userdata=""
    if "post_script" in kwargs:
        with open(kwargs["post_script"], "r") as post_script:
            userdata = post_script.read()
    nics = list()
    for entry in kwargs["networks"]:
        json_response = neutron.list_networks(name=entry)
        nets = json_response["networks"]
        net = nets[0]
        nics.append({"net-id": net["id"]})
    nova.servers.create(name=kwargs["name"],
                        flavor=flavor,
                        image=image,
#                        security_groups=kwargs["security_groups"],
                        userdata=userdata,
#                        availability_zone=kwargs["availability_zone"],
                        nics=nics,
                        key_name=kwargs["key_name"])

if __name__ == "__main__":
    sess = get_session()
    instances = get_vm_json()
    for instance in instances:
        print instance["name"]
        create_vm(sess, instance)
        time.sleep(0.25)

