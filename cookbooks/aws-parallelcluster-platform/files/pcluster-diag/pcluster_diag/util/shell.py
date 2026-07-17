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

"""Helpers for running external commands."""

import logging
import pwd
import subprocess  # nosec B404  # callers pass a fixed argument list, no shell
from typing import List, Optional

logger = logging.getLogger(__name__)

# Default command timeout in seconds.
DEFAULT_COMMAND_TIMEOUT_SECONDS = 60


def run_command(
    command: List[str],
    timeout: Optional[int] = DEFAULT_COMMAND_TIMEOUT_SECONDS,
    as_user: Optional[str] = None,
) -> subprocess.CompletedProcess:
    """Run ``command`` without a shell, log its outcome to stderr, and return the CompletedProcess.

    The command is never run through a shell and its return code is not checked, so callers decide how
    to interpret the result. ``timeout`` (seconds, default 60) may be overridden or set to ``None`` to
    disable it.

    When ``as_user`` is given, the command runs with that user's uid/gid via ``setpriv``, which
    changes the process credentials directly. Unlike ``sudo``/``su``/``runuser`` it opens no PAM
    session, so it never triggers side effects such as ``pam_mkhomedir`` creating the user's home
    directory.
    """
    if as_user is not None:
        # Drop privileges with setpriv rather than sudo: sudo opens a PAM session, which on
        # AD-enabled nodes triggers pam_mkhomedir and creates the user's home directory as a side
        # effect. setpriv only changes uid/gid, so a read-only check never mutates the node.
        account = pwd.getpwnam(as_user)
        command = [
            "setpriv",
            "--reuid",
            str(account.pw_uid),
            "--regid",
            str(account.pw_gid),
            "--clear-groups",
        ] + command
    result = subprocess.run(  # nosec B603  # no shell; the argument list is fixed by the caller
        command,
        capture_output=True,
        text=True,
        check=False,
        timeout=timeout,
    )
    logger.info(
        "Executed command %s: exit code %d, stdout=%r, stderr=%r",
        command,
        result.returncode,
        result.stdout,
        result.stderr,
    )
    return result
