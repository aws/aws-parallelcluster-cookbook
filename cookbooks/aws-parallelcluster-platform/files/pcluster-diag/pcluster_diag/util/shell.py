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
import time
from dataclasses import dataclass
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


@dataclass
class TimedCommand:
    """The timed outcome of a command run via :func:`time_command`.

    Attributes:
        command: The command that was executed (argument list).
        returncode: The process exit code, or ``None`` if the command timed out.
        stdout: The captured standard output (may be partial on timeout).
        stderr: The captured standard error (may be partial on timeout).
        elapsed_seconds: Wall-clock duration the command took (or ran before timing out).
        timed_out: ``True`` if the command exceeded its timeout and was killed.
    """

    command: List[str]
    returncode: Optional[int]
    stdout: str
    stderr: str
    elapsed_seconds: float
    timed_out: bool

    @property
    def succeeded(self) -> bool:
        """Return whether the command completed with a zero exit code (and did not time out)."""
        return not self.timed_out and self.returncode == 0


def time_command(command: List[str], timeout: int = DEFAULT_COMMAND_TIMEOUT_SECONDS) -> TimedCommand:
    """Run ``command`` without a shell and measure how long it takes, treating a timeout as data.

    Unlike :func:`run_command`, a timeout does not raise: it is returned as a ``TimedCommand`` with
    ``timed_out=True`` and ``returncode=None``. This matters for latency probes (e.g. directory
    lookups) where a hang is itself the diagnostic signal rather than an error to propagate.
    """
    start = time.perf_counter()
    try:
        result = subprocess.run(  # nosec B603  # no shell; the argument list is fixed by the caller
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout,
        )
        elapsed = time.perf_counter() - start
        timed = TimedCommand(
            command=command,
            returncode=result.returncode,
            stdout=result.stdout,
            stderr=result.stderr,
            elapsed_seconds=elapsed,
            timed_out=False,
        )
    except subprocess.TimeoutExpired as error:
        elapsed = time.perf_counter() - start
        timed = TimedCommand(
            command=command,
            returncode=None,
            stdout=_as_text(error.stdout),
            stderr=_as_text(error.stderr),
            elapsed_seconds=elapsed,
            timed_out=True,
        )
    logger.info(
        "Timed command %s: timed_out=%s, returncode=%s, elapsed=%.3fs",
        command,
        timed.timed_out,
        timed.returncode,
        timed.elapsed_seconds,
    )
    return timed


def _as_text(output) -> str:
    """Normalize captured output (which may be ``None`` or ``bytes`` on timeout) to a string."""
    if output is None:
        return ""
    if isinstance(output, bytes):
        return output.decode("utf-8", errors="replace")
    return output
