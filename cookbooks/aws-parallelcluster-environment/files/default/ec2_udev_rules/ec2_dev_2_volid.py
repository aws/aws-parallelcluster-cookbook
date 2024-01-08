# FIXME: Fix Code Duplication
# pylint: disable=R0801

import json
import os
import re
import sys
import syslog


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


def main():
    syslog.syslog("Starting ec2_dev_2_volid.py script")
    try:
        dev = str(sys.argv[1])
        validate_device_name(dev)
        syslog.syslog(f"Input block device is {dev}")
    except IndexError:
        syslog.syslog(syslog.LOG_ERR, "Provide block device i.e. xvdf")
    dev = adapt_device_name(dev)
    mapping_file_path = "/dev/disk/by-ebs-volumeid/parallelcluster_dev_id_mapping"
    if os.path.isfile(mapping_file_path):
        with open(mapping_file_path, "r", encoding="utf-8") as mapping_file:
            mapping = json.load(mapping_file)
    else:
        mapping = {}
    volume_id = mapping.get(dev)
    print(volume_id)


if __name__ == "__main__":
    main()
