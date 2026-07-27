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

"""Common command doubles and canned command output shared across the suite.

Kept separate from :mod:`tests.sample_data` (which holds domain models -- Contexts, Check doubles,
Results) so the low-level command stubs and raw command-output samples have one canonical home and do
not drift between test modules.
"""

import subprocess


# --- Command doubles ------------------------------------------------------------------


def completed_process(returncode=0, stdout="", stderr=""):
    """Return a ``subprocess.CompletedProcess`` double for stubbing ``run_command``."""
    return subprocess.CompletedProcess(args=["cmd"], returncode=returncode, stdout=stdout, stderr=stderr)


def raise_oserror(command):
    """Raise ``FileNotFoundError`` for ``command`` -- stubs a missing binary in ``run_command``."""
    raise FileNotFoundError(command[0])


# --- Lustre command output fixtures (canonical copies) --------------------------------

# A representative healthy ``lfs df -h``: one MDT and two OSTs, all reporting capacity.
HEALTHY_LFS_DF = """\
UUID                       bytes        Used   Available Use% Mounted on
fs-abc-MDT0000_UUID         2.0G       10.0M        1.9G   1% /fsx[MDT:0]
fs-abc-OST0000_UUID        10.0T        1.0T        9.0T  10% /fsx[OST:0]
fs-abc-OST0001_UUID        10.0T        2.0T        8.0T  20% /fsx[OST:1]

filesystem_summary:        20.0T        3.0T       17.0T  15% /fsx
"""

# A degraded ``lfs df -h`` where OST0001 reports an error instead of capacity.
DEGRADED_LFS_DF = """\
UUID                       bytes        Used   Available Use% Mounted on
fs-abc-MDT0000_UUID         2.0G       10.0M        1.9G   1% /fsx[MDT:0]
fs-abc-OST0000_UUID        10.0T        1.0T        9.0T  10% /fsx[OST:0]
fs-abc-OST0001_UUID : Resource temporarily unavailable

filesystem_summary:        10.0T        1.0T        9.0T  10% /fsx
"""
