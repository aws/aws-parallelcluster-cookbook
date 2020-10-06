import requests
import sys
import os
import syslog
import time
import boto3
import configparser
from botocore.config import Config


def main():
    syslog.syslog("Starting ec2_dev_2_volid.py script")
    # Get dev
    try:
        dev = str(sys.argv[1])
        syslog.syslog("Input block device is %s" % dev)
    except IndexError:
        syslog.syslog(syslog.LOG_ERR, "Provide block device i.e. xvdf")

    # Convert dev to mapping format
    if 'nvme' in dev:
        # For newer instances which expose EBS volumes as NVMe devices, translate the
        # device name so boto can discover it.
        output = os.popen('sudo /sbin/ebsnvme-id /dev/' + dev).read().split(":")[1].strip()
        print(output)
        sys.exit(0)
    else:
        dev = dev.replace('xvd', 'sd')
        dev = '/dev/' + dev

    # Get instance ID
    instanceId = requests.get("http://169.254.169.254/latest/meta-data/instance-id").text

    # Get region
    region = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone").text
    region = region[:-1]

    # Parse configuration file to read proxy settings
    config = configparser.RawConfigParser()
    config.read('/etc/boto.cfg')
    proxy_config = Config()
    if config.has_option('Boto', 'proxy') and config.has_option('Boto', 'proxy_port'):
        proxy = config.get('Boto', 'proxy')
        proxy_port = config.get('Boto', 'proxy_port')
        proxy_config = Config(proxies={'https': "{0}:{1}".format(proxy, proxy_port)})

    # Connect to AWS using boto
    ec2 = boto3.client('ec2', region_name=region, config=proxy_config)

    # Poll for blockdevicemapping
    devices = ec2.describe_instance_attribute(InstanceId=instanceId, Attribute='blockDeviceMapping').get('BlockDeviceMappings')
    devmap = dict((d.get('DeviceName'), d) for d in devices)
    x = 0
    while dev not in devmap:
        if x == 36:
            syslog.syslog("Dev %s did not appears in 180 seconds." % dev)
            sys.exit(1)
        syslog.syslog("Looking for dev %s in devmap %s" % (dev, devmap))
        time.sleep(5)
        devices = ec2.describe_instance_attribute(InstanceId=instanceId, Attribute='blockDeviceMapping').get('BlockDeviceMappings')
        devmap = dict((d.get('DeviceName'), d) for d in devices)
        x += 1

    # Return volumeId
    volumeId = devmap.get(dev).get('Ebs').get('VolumeId')
    print(volumeId)


if __name__ == '__main__':
    main()
