# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""The `describe-checks` subcommand.

Emits, as JSON, the registered diagnostic Checks: their identifiers and descriptions.
"""

import json

import click

from pcluster_diag.core.registry import DEFAULT_REGISTRY


@click.command(name="describe-checks")
def describe_checks() -> None:
    """Describe the registered diagnostic checks.

    Prints to stdout a JSON array listing every registered check, with its identifier
    (``check_id``, the same key a Result carries) and its description (``check_description``), in
    registration order. Only the registry is inspected: no check is executed, no cluster context is
    built, and root privileges are not required.
    """
    checks = [
        {"check_id": check.identifier, "check_description": check.description}
        for check in DEFAULT_REGISTRY.registered_checks()
    ]
    print(json.dumps(checks, indent=2))
