#!/usr/bin/env python
"""Verify the fingerprint for the CloudWatch agent's public key is as expected."""

import re
import subprocess
import sys

# This value comes from the CloudWatch agent's documentation:
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/verify-CloudWatch-Agent-Package-Signature.html
EXPECTED_FINGERPRINT = "9376 16F3 450B 7D80 6CBD  9725 D581 6730 3B78 9C72"


def get_key_identifier():
    """Get identifier for cloudwatch agent's key."""
    output = subprocess.check_output(['gpg', '--list-keys', 'Amazon CloudWatch Agent']).decode('utf-8')
    for line in output.splitlines():
        match = re.search(r'^pub\s+.*/([0-9A-Z]+)', line.strip())
        if match:
            return match.group(1)
    sys.exit('Unable to get identifier for cloudwatch agent public key')


def get_key_fingerprint(key_id):
    """Get the fingerprint for the key with ID key_id."""
    output = subprocess.check_output(['gpg', '--fingerprint', key_id]).decode('utf-8')
    for line in output.splitlines():
        match = re.search(r'Key fingerprint = (.*)', line.strip())
        if match:
            return match.group(1)
    sys.exit('Unable to get fingerprint for cloudwatch agent public key')


def main():
    """Run the script."""
    key_id = get_key_identifier()
    fingerprint = get_key_fingerprint(key_id)
    if fingerprint != EXPECTED_FINGERPRINT:
        sys.exit(
            'Observed fingerprint of cloudwatch agent public key ({observed}) '
            'does not match expected fingerprint ({expected}).'
            .format(observed=fingerprint, expected=EXPECTED_FINGERPRINT)
        )


if __name__ == '__main__':
    main()
