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

"""Helpers for reading the sudo rule definitions, as exported by ``cvtsudoers``.

``cvtsudoers -f json -e`` parses a sudoers file the way sudo does -- following its includes, expanding
aliases and unescaping commands -- and exports its rules as JSON. Only the definitions are read: nothing is
run through sudo, and how sudo would resolve the rules at runtime (rule ordering, negations, group
membership, Defaults) is not evaluated.
"""

import itertools
import json
from typing import List

from pcluster_diag.models.sudoer_definition import SudoerDefinition
from pcluster_diag.util.shell import run_command

CVTSUDOERS_TIMEOUT_SECONDS = 30
# A rule naming no runas user runs its commands as root.
DEFAULT_RUNAS_USER = "root"


class SudoersExportError(RuntimeError):
    """Raised when ``cvtsudoers`` cannot export the sudoers rules (e.g. a sudoers syntax error)."""


def load_definitions(path: str) -> List[SudoerDefinition]:
    """Return the definitions in sudoers file ``path`` and every file it includes.

    Each rule is flattened into one definition per user, runas user and command it names (each may be ``ALL``).
    cvtsudoers also reports SETENV for ``ALL``, where sudo implies it.

    Raises:
        SudoersExportError: If cvtsudoers fails, e.g. on a sudoers syntax error.
    """
    # Sample output (one entry of "User_Specs"; "-e" expands aliases, e.g. SLURM_COMMANDS):
    #
    #     {
    #         "User_List": [
    #             { "username": "pcluster-admin" }
    #         ],
    #         "Host_List": [
    #             { "hostname": "ALL" }
    #         ],
    #         "Cmnd_Specs": [
    #             {
    #                 "runasusers": [
    #                     { "username": "root" }
    #                 ],
    #                 "Options": [
    #                     { "authenticate": false }
    #                 ],
    #                 "Commands": [
    #                     { "command": "/opt/slurm/bin/scontrol" },
    #                     { "command": "/opt/slurm/bin/sinfo" }
    #                 ]
    #             }
    #         ]
    #     }
    #
    # NOPASSWD is exported as {"authenticate": false} and SETENV as {"setenv": true}; a negated member carries
    # "negated": true, and a rule naming no runas user has no "runasusers".
    result = run_command(["cvtsudoers", "-f", "json", "-e", path], timeout=CVTSUDOERS_TIMEOUT_SECONDS)
    if result.returncode != 0:
        raise SudoersExportError(result.stderr.strip() or "cvtsudoers exited with code {}".format(result.returncode))
    return [
        definition
        for user_spec in json.loads(result.stdout).get("User_Specs", [])
        for cmnd_spec in user_spec.get("Cmnd_Specs", [])
        for definition in _definitions(user_spec, cmnd_spec)
    ]


def _definitions(user_spec: dict, cmnd_spec: dict) -> List[SudoerDefinition]:
    """Return the definitions one command spec of a cvtsudoers JSON user spec contains."""
    options = {key: value for option in cmnd_spec.get("Options", []) for key, value in option.items()}
    runas_users = _members(cmnd_spec["runasusers"], "username") if "runasusers" in cmnd_spec else [DEFAULT_RUNAS_USER]
    return [
        SudoerDefinition(
            user,
            runas,
            command,
            nopasswd=options.get("authenticate") is False,
            setenv=options.get("setenv") is True,
        )
        for user, runas, command in itertools.product(
            _members(user_spec.get("User_List", []), "username"),
            runas_users,
            _members(cmnd_spec.get("Commands", []), "command"),
        )
    ]


def _members(members: List[dict], key: str) -> List[str]:
    """Return the ``key`` values of a cvtsudoers member list, skipping negated members and other member kinds."""
    return [member[key] for member in members if key in member and not member.get("negated")]
