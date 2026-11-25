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

"""Check asserting the sudoers files contain the definitions ParallelCluster relies on.

ParallelCluster installs its rules under ``/etc/sudoers.d/99-parallelcluster-*`` and relies on the OS's
``/etc/sudoers`` for root's own. When a definition goes missing -- e.g. host hardening replaces
``/etc/sudoers``, dropping root's rule or the ``#includedir`` -- the daemons fail far from the cause, such
as fleet start/stop failing with ``root is not in the sudoers file``. So each expected definition is looked
up among the definitions in ``/etc/sudoers`` and its includes.
"""

import dataclasses
from typing import Dict, List

from pcluster_diag.core.constants import CLUSTER_ADMIN_USER, ROOT_USER, SCONTROL_PATH, SLURM_USER
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.models.sudoer_definition import SudoerDefinition
from pcluster_diag.util import sudoers as sudoers_policy
from pcluster_diag.util import virtualenvs
from pcluster_diag.util.kernel_module import version_at_least

SUDOERS_PATH = "/etc/sudoers"
SINFO_PATH = "/opt/slurm/bin/sinfo"
SHUTDOWN_PATH = "/usr/sbin/shutdown"
LOGINMGTD_TERMINATION_HOOK_PATH = "/etc/parallelcluster/loginmgtd_on_termination.sh"
# Resolved in run(): clusterstatusmgtd runs cinc-client with --log_level info since ParallelCluster 3.15.0, and with
# --log_level auto before.
CINC_LOG_LEVEL = "{cinc_log_level}"
CINC_LOG_LEVEL_INFO_SINCE = "3.15.0"
# The exact command line clusterstatusmgtd runs: its sudoers rule pins the arguments, so they must match.
CLUSTERSTATUSMGTD_CINC_COMMAND = (
    "/usr/bin/cinc-client --local-mode --config /etc/chef/client.rb --log_level " + CINC_LOG_LEVEL + " "
    "--logfile /var/log/chef-client.log --force-formatter --no-color --chef-zero-port 8889 "
    "--json-attributes /etc/chef/dna.json "
    "--override-runlist aws-parallelcluster-entrypoints::update_computefleet_status"
)
# Resolved in run(): the node virtualenv path embeds the Python version, and resolving it at import would
# crash the whole tool, not just this check, on a node where it is missing.
NODE_VIRTUALENV_BIN = "{node_virtualenv_bin}"
ALL = "ALL"

# The definitions ParallelCluster expects on every node type: 99-parallelcluster-slurm is installed everywhere.
COMMON_DEFINITIONS: List[SudoerDefinition] = [
    SudoerDefinition(CLUSTER_ADMIN_USER, ROOT_USER, SCONTROL_PATH),
    SudoerDefinition(CLUSTER_ADMIN_USER, ROOT_USER, SINFO_PATH),
    SudoerDefinition(CLUSTER_ADMIN_USER, ROOT_USER, SHUTDOWN_PATH),
    # The cookbook grants SETENV to all the Slurm hooks; the resume program needs it to pass SLURM_RESUME_FILE.
    SudoerDefinition(SLURM_USER, CLUSTER_ADMIN_USER, NODE_VIRTUALENV_BIN + "/slurm_resume", setenv=True),
    SudoerDefinition(SLURM_USER, CLUSTER_ADMIN_USER, NODE_VIRTUALENV_BIN + "/slurm_suspend", setenv=True),
    SudoerDefinition(SLURM_USER, CLUSTER_ADMIN_USER, NODE_VIRTUALENV_BIN + "/slurm_fleet_status_manager", setenv=True),
]

HEAD_NODE_DEFINITIONS: List[SudoerDefinition] = [
    # 99-parallelcluster-clusterstatusmgtd
    SudoerDefinition(CLUSTER_ADMIN_USER, ROOT_USER, CLUSTERSTATUSMGTD_CINC_COMMAND),
    # /etc/sudoers: cluster update and fleet start/stop recipes run 'sudo -i' / 'sudo -u' as root.
    # The stock 'root ALL=(ALL) ALL' has no NOPASSWD; cvtsudoers reports SETENV, which sudo implies for ALL.
    SudoerDefinition(ROOT_USER, ALL, ALL, nopasswd=False, setenv=True),
]

LOGIN_NODE_DEFINITIONS: List[SudoerDefinition] = [
    # 99-parallelcluster-loginmgtd
    SudoerDefinition(CLUSTER_ADMIN_USER, ROOT_USER, LOGINMGTD_TERMINATION_HOOK_PATH),
]

# The definitions expected per node type, mirroring where the cookbook installs each
# /etc/sudoers.d/99-parallelcluster-* template, plus root's rule from the OS's /etc/sudoers.
EXPECTED_DEFINITIONS: Dict[NodeType, List[SudoerDefinition]] = {
    NodeType.HEAD: COMMON_DEFINITIONS + HEAD_NODE_DEFINITIONS,
    NodeType.COMPUTE: COMMON_DEFINITIONS,
    NodeType.LOGIN: COMMON_DEFINITIONS + LOGIN_NODE_DEFINITIONS,
}


class Sudoers(Check):
    """Verify the sudoers files contain the definitions ParallelCluster relies on."""

    INVALID_SUDOERS = CheckError(1, "The sudoers files cannot be read: {}")
    NOT_DEFINED = CheckError(2, "The sudoers files do not contain the expected definition: {}.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the sudoers files contain the definitions ParallelCluster relies on."

    def run(self, context: Context) -> Result:
        """Pass when every definition expected on this node is in the sudoers files exactly, tags included."""
        try:
            actual_definitions = sudoers_policy.load_definitions(SUDOERS_PATH)
        except sudoers_policy.SudoersExportError as error:
            return Result.from_findings(self, errors=[self.INVALID_SUDOERS.format(error)])
        expected_definitions = self._resolve_expected_definitions(context)
        errors: List[CheckError] = []
        for expected_definition in expected_definitions:
            if expected_definition not in actual_definitions:
                errors.append(self.NOT_DEFINED.format(expected_definition))
        return Result.from_findings(self, errors=errors)

    @staticmethod
    def _resolve_expected_definitions(context: Context) -> List[SudoerDefinition]:
        """Return the definitions expected on the node, with its virtualenv path and its version's values filled in.

        An unparseable ParallelCluster version gets the values of the current version.
        """
        node_virtualenv_bin = virtualenvs.node_virtualenv_bin()
        older = version_at_least(context.pcluster_version, CINC_LOG_LEVEL_INFO_SINCE) is False
        cinc_log_level = "auto" if older else "info"
        return [
            dataclasses.replace(
                definition,
                command=definition.command.format(
                    node_virtualenv_bin=node_virtualenv_bin, cinc_log_level=cinc_log_level
                ),
            )
            for definition in EXPECTED_DEFINITIONS[context.node_type]
        ]
