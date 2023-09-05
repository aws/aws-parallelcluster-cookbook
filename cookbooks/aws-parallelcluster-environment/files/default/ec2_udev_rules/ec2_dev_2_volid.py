import configparser
import os
import re
import sys
import syslog
import time

import boto3
import requests
from botocore.config import Config

METADATA_REQUEST_TIMEOUT = 60


def get_imdsv2_token():
    # Try with getting IMDSv2 token, fall back to IMDSv1 if can not get the token
    token = requests.put(
        "http://169.254.169.254/latest/api/token",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "300"},
        timeout=METADATA_REQUEST_TIMEOUT,
    )
    headers = {}
    if token.status_code == requests.codes.ok:
        headers["X-aws-ec2-metadata-token"] = token.content
    return headers


def validate_device_name(device_name):
    """
    Validate an argument used to build a subprocess command against a regex pattern.

    The validation is done after forcing the encoding to be the standard Python Unicode / UTF-8
    :param device_name: an argument string to validate
    :raise: Exception if the argument fails to match the patter
    :return: True if the argument matches the pattern
    """
    device_name = (str(device_name).encode("utf-8", "ignore")).decode()
    match = re.match(r"^(\w)+$", device_name)
    if not match:
        raise ValueError("Device name provided argument has an invalid pattern.")
    return True


def adapt_device_name(dev):
    if "nvme" in dev:
        # For newer instances which expose EBS volumes as NVMe devices, translate the
        # device name so boto can discover it.
        #
        # A nosec comment is appended to the following line in order to disable the B605 check.
        # The only current use of this script in the repo sets the `dev` arg to the value of the
        # %k format string in a udev rule, (name given by kernel to device).
        output = (
            os.popen("sudo /usr/local/sbin/parallelcluster-ebsnvme-id -v /dev/" + dev)  # nosec nosemgrep
            .read()
            .split(":")[1]
            .strip()
        )
        print(output)
        sys.exit(0)
    else:
        dev = dev.replace("xvd", "sd")
        dev = "/dev/" + dev
    return dev


def parse_proxy_config():
    config = configparser.RawConfigParser()
    config.read("/etc/boto.cfg")
    proxy_config = Config()
    if config.has_option("Boto", "proxy") and config.has_option("Boto", "proxy_port"):
        proxy = config.get("Boto", "proxy")
        proxy_port = config.get("Boto", "proxy_port")
        proxy_config = Config(proxies={"https": f"{proxy}:{proxy_port}"})
    return proxy_config


def get_device_volume_id(ec2, dev, instance_id):
    # Poll for blockdevicemapping
    devices = ec2.describe_instance_attribute(InstanceId=instance_id, Attribute="blockDeviceMapping").get(
        "BlockDeviceMappings"
    )
    dev_map = dict((d.get("DeviceName"), d) for d in devices)
    loop_count = 0
    while dev not in dev_map:
        if loop_count == 36:
            syslog.syslog(f"Dev {dev} did not appears in 180 seconds.")
            sys.exit(1)
        syslog.syslog(f"Looking for dev {dev} in dev_map {dev_map}")
        time.sleep(5)
        devices = ec2.describe_instance_attribute(InstanceId=instance_id, Attribute="blockDeviceMapping").get(
            "BlockDeviceMappings"
        )
        dev_map = dict((d.get("DeviceName"), d) for d in devices)
        loop_count += 1

    return dev_map.get(dev).get("Ebs").get("VolumeId")


def get_metadata_value(token, metadata_path):
    return requests.get(
        metadata_path,
        headers=token,
        timeout=METADATA_REQUEST_TIMEOUT,
    ).text


def main():
    syslog.syslog("Starting ec2_dev_2_volid.py script")
    try:
        dev = str(sys.argv[1])
        validate_device_name(dev)
        syslog.syslog(f"Input block device is {dev}")
    except IndexError:
        syslog.syslog(syslog.LOG_ERR, "Provide block device i.e. xvdf")

    dev = adapt_device_name(dev)

    token = get_imdsv2_token()

    instance_id = get_metadata_value(token, "http://169.254.169.254/latest/meta-data/instance-id")

    region = get_metadata_value(token, "http://169.254.169.254/latest/meta-data/placement/availability-zone")
    region = region[:-1]

    proxy_config = parse_proxy_config()

    # Configure the AWS CA bundle.
    # In US isolated regions the dedicated CA bundle will be used.
    # In any other region, the default bundle will be used (None stands for the default settings).
    # Note: We want to apply a more general solution that applies to every region,
    # but for the time being this is enough to support US isolated regions without
    # impacting the other ones.
    ca_bundle = f"/etc/pki/{region}/certs/ca-bundle.pem" if region.startswith("us-iso") else None

    ec2 = boto3.client("ec2", region_name=region, config=proxy_config, verify=ca_bundle)

    volume_id = get_device_volume_id(ec2, dev, instance_id)
    print(volume_id)


if __name__ == "__main__":
    main()
