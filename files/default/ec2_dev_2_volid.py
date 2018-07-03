#!/usr/bin/env python

import boto.ec2
import urllib2
import sys
import os
import syslog
import time

# Get dev
try:
    dev = str(sys.argv[1])
except IndexError:
    syslog.syslog(syslog.LOG_ERR, "Provide block device i.e. xvdf")
    sys.exit(1)

# Convert dev to mapping format
if 'nvme' in dev:
    # For newer instances which expose EBS volumes as NVMe devices, translate the
    # device name so boto can discover it.
    output = os.popen('sudo /usr/local/sbin/cfncluster-ebsnvme-id -v /dev/' + dev).read().split(":")[1].strip()
    print(output)
    sys.exit(0)
else:
    dev = dev.replace('xvd', 'sd')
    dev = '/dev/' + dev

# Get instance ID
instanceId = urllib2.urlopen("http://169.254.169.254/latest/meta-data/instance-id").read()

# Get region
region = urllib2.urlopen("http://169.254.169.254/latest/meta-data/placement/availability-zone").read()
region = region[:-1]

# Connect to AWS using boto
conn = boto.ec2.connect_to_region(region)

# Poll for blockdevicemapping
attrib = conn.get_instance_attribute(instanceId, 'blockDeviceMapping')
devmap = attrib.get('blockDeviceMapping')
x = 0
while not devmap.has_key(dev):
    if x == 36:
        syslog.syslog("Dev %s did not appears in 180 seconds." % dev)
        sys.exit(1)
    syslog.syslog("Looking for dev %s into devmap %s" % (dev, devmap))
    time.sleep(5)
    attrib = conn.get_instance_attribute(instanceId, 'blockDeviceMapping')
    devmap = attrib.get('blockDeviceMapping')
    x += 1

print(devmap[dev].volume_id)
