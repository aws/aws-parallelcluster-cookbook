import sys
import subprocess
import os
import requests
import boto3
import time
import configparser
from botocore.config import Config


def convert_dev(dev):
    # Translate the device name as provided by the OS to the one used by EC2
    # FIXME This approach could be broken in some OS variants, see
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html#identify-nvme-ebs-device
    if '/nvme' in dev:
        return '/dev/' + os.popen('sudo /usr/local/sbin/parallelcluster-ebsnvme-id -u -b ' + dev).read().strip()
    elif '/hd' in dev:
        return dev.replace('hd', 'sd')
    elif '/xvd' in dev:
        return dev.replace('xvd', 'sd')
    else:
        return dev

def get_all_devices():
    # lsblk -d -n
    # xvda 202:0    0  17G  0 disk
    # xvdb 202:16   0  20G  0 disk /shared
    command = ["/bin/lsblk", "-d", "-n"]

    try:
        output = subprocess.check_output(command, stderr=subprocess.STDOUT, universal_newlines=True).split("\n")
        return ["/dev/{}".format(line.split()[0]) for line in output if len(line.split()) > 0]
    except subprocess.CalledProcessError as e:
        print("Failed to get devices with lsblk -d -n")
        raise e

def main():
    # Get EBS volume Id
    try:
        volumeId = str(sys.argv[1])
    except IndexError:
        print("Provide an EBS volume ID to attach i.e. vol-cc789ea5")
        sys.exit(1)

    # Get instance ID
    instanceId = requests.get("http://169.254.169.254/latest/meta-data/instance-id").text

    # Get region
    region = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone").text
    region = region[:-1]

    # Generate a list of system paths minus the root path
    paths = [convert_dev(device) for device in get_all_devices()]

    # List of possible block devices
    blockDevices = ['/dev/sdb', '/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh',
                    '/dev/sdi','/dev/sdj', '/dev/sdk', '/dev/sdl', '/dev/sdm', '/dev/sdn', '/dev/sdo',
                    '/dev/sdp', '/dev/sdq', '/dev/sdr', '/dev/sds', '/dev/sdt', '/dev/sdu', '/dev/sdv',
                    '/dev/sdw', '/dev/sdx', '/dev/sdy', '/dev/sdz']

    # List of available block devices after removing currently used block devices
    availableDevices = [a for a in blockDevices if a not in paths]

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

    # Attach the volume
    dev = availableDevices[0]
    response = ec2.attach_volume(VolumeId=volumeId, InstanceId=instanceId, Device=dev)

    # Poll for volume to attach
    state = response.get("State")
    x = 0
    while state != "attached":
        if x == 36:
            print("Volume %s failed to mount in 180 seconds." % volumeId)
            exit(1)
        if state in ["busy" or "detached"]:
            print("Volume %s in bad state %s" % (volumeId, state))
            exit(1)
        print("Volume %s in state %s ... waiting to be 'attached'" % (volumeId, state))
        time.sleep(5)
        x += 1
        try:
            state = ec2.describe_volumes(VolumeIds=[volumeId]).get('Volumes')[0].get('Attachments')[0].get('State')
        except IndexError as e:
            continue


if __name__ == '__main__':
    main()