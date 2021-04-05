import configparser
import os
import subprocess
import sys
import time

import boto3
import requests
from botocore.config import Config


def convert_dev(dev):
    # Translate the device name as provided by the OS to the one used by EC2
    # FIXME This approach could be broken in some OS variants, see
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html#identify-nvme-ebs-device
    #
    # A nosec comment is appended to the following line in order to disable the B605 check.
    # The only current use of this script in the repo sets the `dev` arg to the value of a device name
    # obtained via the OS.
    if "/nvme" in dev:
        return (
            "/dev/"
            + os.popen("sudo /usr/local/sbin/parallelcluster-ebsnvme-id -u -b " + dev).read().strip()  # nosemgrep
        )
    elif "/hd" in dev:
        return dev.replace("hd", "sd")
    elif "/xvd" in dev:
        return dev.replace("xvd", "sd")
    else:
        return dev


def get_all_devices():
    # lsblk -d -n
    # xvda 202:0    0  17G  0 disk
    # xvdb 202:16   0  20G  0 disk /shared
    command = ["/bin/lsblk", "-d", "-n"]

    try:
        # fmt: off
        output = subprocess.check_output(  # nosec
            command, stderr=subprocess.STDOUT, universal_newlines=True
        ).split("\n")
        # fmt: on
        return ["/dev/{}".format(line.split()[0]) for line in output if len(line.split()) > 0]
    except subprocess.CalledProcessError as e:
        print("Failed to get devices with lsblk -d -n")
        raise e


def main():
    # Get EBS volume Id
    try:
        volume_id = str(sys.argv[1])
    except IndexError:
        print("Provide an EBS volume ID to attach i.e. vol-cc789ea5")
        sys.exit(1)

    # Get instance ID
    token = requests.put(
        "http://169.254.169.254/latest/api/token",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"}
    )
    headers = {}
    if token.status_code == requests.codes.ok:
        headers["X-aws-ec2-metadata-token"] = token.content
    instance_id = requests.get("http://169.254.169.254/latest/meta-data/instance-id", headers=headers).text

    # Get region
    region = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone", headers=headers).text
    region = region[:-1]

    # Generate a list of system paths minus the root path
    paths = [convert_dev(device) for device in get_all_devices()]

    # List of possible block devices
    block_devices = [
        "/dev/sdb",
        "/dev/sdc",
        "/dev/sdd",
        "/dev/sde",
        "/dev/sdf",
        "/dev/sdg",
        "/dev/sdh",
        "/dev/sdi",
        "/dev/sdj",
        "/dev/sdk",
        "/dev/sdl",
        "/dev/sdm",
        "/dev/sdn",
        "/dev/sdo",
        "/dev/sdp",
        "/dev/sdq",
        "/dev/sdr",
        "/dev/sds",
        "/dev/sdt",
        "/dev/sdu",
        "/dev/sdv",
        "/dev/sdw",
        "/dev/sdx",
        "/dev/sdy",
        "/dev/sdz",
    ]

    # List of available block devices after removing currently used block devices
    available_devices = [a for a in block_devices if a not in paths]

    # Parse configuration file to read proxy settings
    config = configparser.RawConfigParser()
    config.read("/etc/boto.cfg")
    proxy_config = Config()
    if config.has_option("Boto", "proxy") and config.has_option("Boto", "proxy_port"):
        proxy = config.get("Boto", "proxy")
        proxy_port = config.get("Boto", "proxy_port")
        proxy_config = Config(proxies={"https": "{0}:{1}".format(proxy, proxy_port)})

    # Connect to AWS using boto
    ec2 = boto3.client("ec2", region_name=region, config=proxy_config)

    # Attach the volume
    dev = available_devices[0]
    response = ec2.attach_volume(VolumeId=volume_id, InstanceId=instance_id, Device=dev)

    # Poll for volume to attach
    state = response.get("State")
    x = 0
    while state != "attached":
        if x == 60:
            print("Volume %s failed to mount in 300 seconds." % volume_id)
            exit(1)
        if state in ["busy" or "detached"]:
            print("Volume %s in bad state %s" % (volume_id, state))
            exit(1)
        print("Volume %s in state %s ... waiting to be 'attached'" % (volume_id, state))
        time.sleep(5)
        x += 1
        try:
            state = ec2.describe_volumes(VolumeIds=[volume_id]).get("Volumes")[0].get("Attachments")[0].get("State")
        except IndexError:
            continue


if __name__ == "__main__":
    main()
