#!/usr/bin/env python

import sys
import parted
import urllib2
import boto3
import time

# Get volumeId
try:
  volumeId = str(sys.argv[1])
except IndexError:
  print "Provide an EBS volume ID to attach i.e. vol-cc789ea5"
  sys.exit(1)

# Get instance ID
instanceId = urllib2.urlopen("http://169.254.169.254/latest/meta-data/instance-id").read()

# Get region
region = urllib2.urlopen("http://169.254.169.254/latest/meta-data/placement/availability-zone").read()
region = region[:-1]

# Generate a list of system paths minus the root path
paths = [ device.path for device in parted.getAllDevices() ]

# List of possible block devices
blockDevices = [ '/dev/xvdb', '/dev/xvdc', '/dev/xvdd', '/dev/xvde', '/dev/xvdf', '/dev/xvdg', '/dev/xvdh', '/dev/xvdi', '/dev/xvdj', '/dev/xvdk', '/dev/xvdl', '/dev/xvdm', '/dev/xvdn', '/dev/xvdo', '/dev/xvdp', '/dev/xvdq', '/dev/xvdr', '/dev/xvds', '/dev/xvdt', '/dev/xvdu', '/dev/xvdv', '/dev/xvdw', '/dev/xvdx', '/dev/xvdy', '/dev/xvdz' ]

# List of available block devices after removing currently used block devices
availableDevices = [a for a in blockDevices if a not in paths]

# Connect to AWS using boto
ec2 = boto3.client('ec2', region_name=region)

# Attach the volume
dev = availableDevices[0].replace('xvd', 'sd')
response = ec2.attach_volume(VolumeId=volumeId, InstanceId=instanceId, Device=dev)

# Poll for volume to attach
state = response.get("State")

x = 0
while state != "attached":
    if x == 36:
        print "Volume %s failed to mount in 180 seconds." % (volumeId)
        exit(1)
    if state in ["busy" or "detached"]:
        print "Volume %s in bad state %s" % (volumeId, state)
        exit(1)
    print "Volume %s in state %s ... waiting to be 'attached'" % (volumeId, state)
    time.sleep(5)
    state = ec2.describe_volumes(VolumeIds=[volumeId]).get('Volumes')[0].get('Attachments')[0].get('State')
    x += 1
