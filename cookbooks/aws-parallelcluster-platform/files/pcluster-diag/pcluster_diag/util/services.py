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

"""Helpers for querying the state of supervisord-managed programs."""

import glob
from typing import Optional

from pcluster_diag.core.constants import SUPERVISORCTL_GLOB, SUPERVISORD_RUNNING_STATE
from pcluster_diag.util.shell import run_command


def get_supervisord_program_state(program: str) -> str:
    """Return the supervisord state token for ``program`` (e.g. RUNNING, STOPPED, FATAL, EXITED).

    Raises:
        RuntimeError: If supervisorctl cannot report the program status.
    """
    command = [_resolve_supervisorctl(), "status", program]
    result = run_command(command)
    state = _program_state(program, result.stdout)
    if state is None:
        raise RuntimeError(
            "Could not parse the status of supervisord program '{}'. supervisorctl output: {!r}".format(
                program, result.stdout
            )
        )
    return state


def is_supervisord_program_running(program: str) -> bool:
    """Return whether the given supervisord program is currently RUNNING.

    Raises:
        RuntimeError: If supervisorctl cannot report the program status.
    """
    return get_supervisord_program_state(program) == SUPERVISORD_RUNNING_STATE


def _resolve_supervisorctl() -> str:
    """Return the path to the cookbook virtualenv's ``supervisorctl`` binary.

    Raises:
        FileNotFoundError: If the ``supervisorctl`` binary cannot be located.
    """
    matches = sorted(glob.glob(SUPERVISORCTL_GLOB))
    if not matches:
        raise FileNotFoundError(
            "Could not locate the supervisorctl binary (looked in '{}').".format(SUPERVISORCTL_GLOB)
        )
    return matches[0]


def _program_state(program: str, status_output: str) -> Optional[str]:
    """Return the status token reported for ``program`` in ``status_output``, or None if unparseable.

    ``supervisorctl status`` prints ``<name> <STATUS> <description>`` per program.
    If the status cannot be parsed, None is returned.
    """
    for line in status_output.splitlines():
        tokens = line.split()
        if not tokens:
            continue
        name = tokens[0].rstrip(":")
        if name == program:
            return tokens[1] if len(tokens) >= 2 else None
    return None
