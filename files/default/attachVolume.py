#!/usr/bin/env python

import sys
import parted
import urllib2
import boto3
import time
import ConfigParser
from botocore.config import Config


def main():
    # Get EBS volume Id
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
    paths = [device.path for device in parted.getAllDevices()]

    # List of possible block devices
    blockDevices = ['/dev/xvdb', '/dev/xvdc', '/dev/xvdd', '/dev/xvde', '/dev/xvdf', '/dev/xvdg', '/dev/xvdh',
                    '/dev/xvdi','/dev/xvdj', '/dev/xvdk', '/dev/xvdl', '/dev/xvdm', '/dev/xvdn', '/dev/xvdo',
                    '/dev/xvdp', '/dev/xvdq', '/dev/xvdr', '/dev/xvds', '/dev/xvdt', '/dev/xvdu', '/dev/xvdv',
                    '/dev/xvdw', '/dev/xvdx', '/dev/xvdy', '/dev/xvdz' ]

    # List of available block devices after removing currently used block devices
    availableDevices = [a for a in blockDevices if a not in paths]

    # Parse configuration file to read proxy settings
    config = ConfigParser.RawConfigParser()
    config.read('/etc/boto.cfg')
    proxy_config = Config()
    if config.has_option('Boto', 'proxy') and config.has_option('Boto', 'proxy_port'):
        proxy = config.get('Boto', 'proxy')
        proxy_port = config.get('Boto', 'proxy_port')
        proxy_config = Config(proxies={'https': "{}:{}".format(proxy, proxy_port)})

    # Connect to AWS using boto
    ec2 = boto3.client('ec2', region_name=region, config=proxy_config)

    # Attach the volume
    dev = availableDevices[0].replace('xvd', 'sd')
    response = ec2.attach_volume(VolumeId=volumeId, InstanceId=instanceId, Device=dev)

    # Poll for volume to attach
    state = response.get("State")
    x = 0
    while state != "attached":
        if x == 36:
            print "Volume %s failed to mount in 180 seconds." % volumeId
            exit(1)
        if state in ["busy" or "detached"]:
            print "Volume %s in bad state %s" % (volumeId, state)
            exit(1)
        print "Volume %s in state %s ... waiting to be 'attached'" % (volumeId, state)
        time.sleep(5)
        x += 1
        try:
            state = ec2.describe_volumes(VolumeIds=[volumeId]).get('Volumes')[0].get('Attachments')[0].get('State')
        except IndexError as e:
            continue


if __name__ == '__main__':
    main()