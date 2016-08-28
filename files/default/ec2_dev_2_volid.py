#!/usr/bin/env python

import boto.ec2
import urllib2
import sys

# Get dev
try:
  dev = str(sys.argv[1])
except IndexError:
  print "Provide block device i.e. xvdf"
  sys.exit(1)

# Convert dev to mapping format
dev = dev.replace('xvd', 'sd')
dev = '/dev/' + dev

# Get instance ID
instanceId = urllib2.urlopen("http://169.254.169.254/latest/meta-data/instance-id").read()

# Get region
region = urllib2.urlopen("http://169.254.169.254/latest/meta-data/placement/availability-zone").read()
region = region[:-1]

# Connect to AWS using boto
conn = boto.ec2.connect_to_region(region)

# Get blockdevicemapping
attrib = conn.get_instance_attribute(instanceId, 'blockDeviceMapping')
devmap = attrib.get('blockDeviceMapping')

if devmap.has_key(dev):
  print devmap[dev].volume_id
else:
  sys.exit(1)
