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

"""Checks dumping the configuration of the cluster, so that it can be compared with a test environment.

The dump goes to the details files of the report: the configuration files of the node (Slurm, SSSD, the ParallelCluster
daemons, ...) with their secrets redacted, and the AWS resources the cluster configuration references (launch
templates, security groups, subnets and their routing, IAM roles and policies, custom action scripts, existing shared
storage). The cluster configuration and dna.json are not dumped: every report holds them in its context, and the
changes of every cluster update are in the details of ClusterUpdateHistory.

The IAM role ParallelCluster gives the head node does not allow reading security groups, subnets, IAM or shared
storage, so the dump of the referenced resources is opt-in, and the resources the credentials cannot read are reported
in a warning. Running pcluster-diag with credentials that allow reading them, e.g. through the ``AWS_PROFILE``
environment variable, collects them.
"""

from collections import defaultdict
from typing import Dict, Iterable, List

from pcluster_diag.core.constants import CORE_SETTINGS_FILE_PATTERNS, LAUNCH_TEMPLATES_CONFIG_PATH
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import config_files
from pcluster_diag.util.config_files import ConfigFile
from pcluster_diag.util.referenced_resources import ReadFailure, ResourceReader

FILE_UNREADABLE = CheckError(INTERNAL_ERROR_CODE, "Could not read {}: {}.")


def _unreadable(files: List[ConfigFile]) -> List[CheckFinding]:
    """Return an error for each file of ``files`` that could not be read."""
    return [FILE_UNREADABLE.format(config_file.path, config_file.error) for config_file in files if config_file.error]


class CoreSettings(Check):
    """Dump the configuration files of the node: Slurm, SSSD, the ParallelCluster daemons, NFS exports, fstab, ..."""

    COLLECTED = CheckInfo(1, "Collected {} configuration files, with their secrets redacted.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Dump the configuration files of the node (Slurm, SSSD, ParallelCluster daemons, ...)."

    def run(self, context: Context) -> Result:
        """Dump the configuration files present on the node, which differ by node type."""
        files = config_files.read_config_files(CORE_SETTINGS_FILE_PATTERNS)
        return Result.from_findings(
            self,
            errors=_unreadable(files) or None,
            infos=[self.COLLECTED.format(len(files))],
            details=config_files.render(files) if files else None,
        )


class ReferencedResources(Check):
    """Dump the AWS resources the cluster configuration references, as AWS describes them.

    The check is opt-in (``approval_required``): it makes AWS calls for every resource, and the IAM role of the head
    node does not allow reading most of them, so it runs only when the user confirms it, or passes ``--yes``.
    """

    PERMISSIONS_MISSING = CheckWarning(
        1,
        "The credentials do not allow reading some resources, which are recorded with their error: {}. To collect "
        "them, run pcluster-diag with credentials that allow these actions.",
    )
    READ_FAILED = CheckWarning(2, "Some resources could not be read, and are recorded with their error: {}.")

    NO_REGION = CheckError(INTERNAL_ERROR_CODE, "The region of the cluster is not in dna.json: no resource was read.")

    COLLECTED = CheckInfo(
        1,
        "Collected {} launch templates, {} security groups, {} subnets, {} IAM roles, {} IAM policies, {} custom "
        "action scripts and {} existing shared storage.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Dump the security groups, subnets, IAM roles, custom actions and shared storage the cluster references."

    def should_run(self, context: Context) -> bool:
        """Run only on the head node: the resources are the same for every node, and only its IAM role can read some."""
        return context.node_type == NodeType.HEAD

    def approval_required(self, context: Context) -> bool:
        """Require confirmation, since most resources need more permissions than the IAM role of the head node."""
        return True

    def run(self, context: Context) -> Result:
        """Read every referenced resource; the ones that cannot be read are reported in a warning."""
        cluster = (context.dna_json or {}).get("cluster") or {}
        if not cluster.get("region"):
            return Result.from_findings(self, errors=[self.NO_REGION])
        reader = ResourceReader(cluster["region"])
        resources = reader.read(
            context.cluster_config or {}, cluster.get("stack_name"), context.instance_id, LAUNCH_TEMPLATES_CONFIG_PATH
        )

        denied = [failure for failure in reader.failures if failure.error in _PERMISSION_ERRORS]
        failed = [failure for failure in reader.failures if failure.error not in _PERMISSION_ERRORS]
        warnings: List[CheckFinding] = []
        if denied:
            warnings.append(self.PERMISSIONS_MISSING.format(", ".join(_unique(failure.action for failure in denied))))
        if failed:
            warnings.append(self.READ_FAILED.format(_describe_failures(failed)))
        infos = [
            self.COLLECTED.format(
                len(resources["launch_templates"]),
                len(resources["security_groups"]),
                len(resources["subnets"]),
                len(resources["iam_roles"]),
                len(resources["iam_policies"]),
                len(resources["custom_action_scripts"]),
                len(resources["shared_storage"]),
            )
        ]
        return Result.from_findings(self, warnings=warnings or None, infos=infos, details=resources)


# The error codes AWS returns when the credentials do not allow an action: IAM, S3 and CloudFormation; EC2; EFS and FSx.
_PERMISSION_ERRORS = frozenset({"AccessDenied", "UnauthorizedOperation", "AccessDeniedException"})


def _unique(items: Iterable[str]) -> List[str]:
    """Return ``items`` without duplicates, in their order."""
    return list(dict.fromkeys(items))


def _describe_failures(failures: List[ReadFailure]) -> str:
    """Return the failed actions grouped by error, e.g. ``Throttling (ec2:DescribeSubnets, iam:GetRole)``."""
    actions_by_error: Dict[str, List[str]] = defaultdict(list)
    for failure in failures:
        actions_by_error[failure.error].append(failure.action)
    return "; ".join(
        "{} ({})".format(error, ", ".join(_unique(actions))) for error, actions in actions_by_error.items()
    )
