import configparser
import os
import subprocess
import sys
import time

import boto3
import requests
from botocore.config import Config
import argparse


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


def get_imdsv2_token():
    # Try with getting IMDSv2 token, fall back to IMDSv1 if can not get the token
    token = requests.put(
        "http://169.254.169.254/latest/api/token",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"}
    )
    headers = {}
    if token.status_code == requests.codes.ok:
        headers["X-aws-ec2-metadata-token"] = token.content
    return headers


def attach_volume(volume_id, instance_id, ec2):
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

    # Attach the volume
    dev = available_devices[0]
    response = ec2.attach_volume(VolumeId=volume_id, InstanceId=instance_id, Device=dev)

    # Poll for volume to attach
    state = response.get("State")
    delay = 5  # seconds
    elapsed = 0
    timeout = 300  # seconds
    while state != "attached":
        if elapsed >= timeout:
            print("ERROR: Volume %s failed to mount in % seconds." % (volume_id, timeout))
            exit(1)
        if state in ["busy", "detached"]:
            print("ERROR: Volume %s in bad state %s" % (volume_id, state))
            exit(1)
        print("Volume %s in state %s ... waiting to be 'attached'" % (volume_id, state))
        time.sleep(delay)
        elapsed += delay
        try:
            state = ec2.describe_volumes(VolumeIds=[volume_id]).get("Volumes")[0].get("Attachments")[0].get("State")
        except IndexError:
            continue


def detach_volume(volume_id, ec2):
    response = ec2.detach_volume(VolumeId=volume_id)

    # Poll for volume to attach
    state = response.get("State")
    delay = 5  # seconds
    elapsed = 0
    timeout = 300  # seconds
    while state != "available":
        if elapsed >= timeout:
            print("ERROR: Volume %s failed to detach in %s seconds." % (volume_id, timeout))
            exit(1)
        if state in ["busy", "attached"]:
            print("ERROR: Volume %s in bad state %s" % (volume_id, state))
            exit(1)
        print("Volume %s in state %s ... waiting to be 'detach'" % (volume_id, state))
        time.sleep(delay)
        elapsed += delay
        try:
            state = ec2.describe_volumes(VolumeIds=[volume_id]).get("Volumes")[0].get("State")
        except IndexError:
            continue


def parse_proxy_config():
    """Parse configuration file to read proxy settings."""
    config = configparser.RawConfigParser()
    config.read("/etc/boto.cfg")
    proxy_config = Config()
    if config.has_option("Boto", "proxy") and config.has_option("Boto", "proxy_port"):
        proxy = config.get("Boto", "proxy")
        proxy_port = config.get("Boto", "proxy_port")
        proxy_config = Config(proxies={"https": "{0}:{1}".format(proxy, proxy_port)})
    return proxy_config


def handle_volume(volume_id, attach, detach):
    # Get IMDSv2 token
    token = get_imdsv2_token()

    # Get instance ID
    instance_id = requests.get("http://169.254.169.254/latest/meta-data/instance-id", headers=token).text

    # Get region
    region = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone", headers=token).text
    region = region[:-1]

    # Parse configuration file to read proxy settings
    proxy_config = parse_proxy_config()

    # Connect to AWS using boto
    ec2 = boto3.client("ec2", region_name=region, config=proxy_config)

    if attach:
        attach_volume(volume_id, instance_id, ec2)
    elif detach:
        detach_volume(volume_id, ec2)


def main():
    try:
        parser = argparse.ArgumentParser(description="Attach or detach ebs volume")
        parser.add_argument(
            "--attach", action="store_true", help="Attach EBS volume", required=False, default=False,
        )
        parser.add_argument(
            "--detach", action="store_true", help="Detach EBS volume", required=False, default=False,
        )
        parser.add_argument(
            "--volume-id",
            required=True,
        )
        args = parser.parse_args()
        if not args.attach and not args.detach:
            raise Exception("Must specify attach or detach action.")
        handle_volume(args.volume_id, args.attach, args.detach)

    except Exception as e:
        print("ERROR: Failed to attach or detach volume, exception: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
