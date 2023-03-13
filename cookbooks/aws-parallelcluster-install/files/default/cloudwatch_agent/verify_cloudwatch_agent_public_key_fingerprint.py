#!/usr/bin/env python
"""Verify the fingerprint for the CloudWatch agent's public key is as expected."""

import sys

import gnupg

# This value comes from the CloudWatch agent's documentation:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/verify-CloudWatch-Agent-Package-Signature.html
EXPECTED_FINGERPRINT = "937616F3450B7D806CBD9725D58167303B789C72"


def get_key_fingerprint():
    """Get identifier for CloudWatch agent's key."""
    keys = gnupg.GPG().list_keys(keys="Amazon CloudWatch Agent")
    for key in keys:
        if "Amazon CloudWatch Agent" in key.get("uids"):
            return key.get("fingerprint")
    sys.exit("Unable to get CloudWatch Agent's public key fingerprint.")


def main():
    """Run the script."""
    fingerprint = get_key_fingerprint()
    if fingerprint != EXPECTED_FINGERPRINT:
        sys.exit(
            f"Observed fingerprint of cloudwatch agent public key ({fingerprint}) "
            f"does not match expected fingerprint ({EXPECTED_FINGERPRINT})."
        )


if __name__ == "__main__":
    main()
