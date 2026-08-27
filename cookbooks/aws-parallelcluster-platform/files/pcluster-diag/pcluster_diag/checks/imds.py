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

"""Check asserting that IMDS is responsive, functional, and enforces per-user access."""

import logging
from typing import List, Optional

from pcluster_diag.core.constants import CLUSTER_ADMIN_USER, ROOT_USER, SLURM_USER
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckWarning
from pcluster_diag.models.result import Result
from pcluster_diag.util import imds

logger = logging.getLogger(__name__)

# The IMDS lockdown is applied only on head and login nodes (see the cookbook's imds recipe).
_LOCKDOWN_NODE_TYPES = (NodeType.HEAD, NodeType.LOGIN)


class Imds(Check):
    """Verify IMDS is responsive and functional.

    Beyond responsiveness this checks that instance tags are reachable, that IMDS reports the instance's
    IAM role, and that per-user reachability matches the Imds/Secured configuration.
    """

    NOT_RESPONSIVE = CheckError(1, "The IMDS version enabled for the cluster ({}) did not respond.")
    UNEXPECTEDLY_DENIED = CheckError(2, "IMDS is not reachable by user '{}', but it should be.")
    UNEXPECTEDLY_ALLOWED = CheckError(3, "IMDS is reachable by user '{}', but it should be denied.")
    NO_ROLE_FROM_IMDS = CheckError(4, "IMDS reports no IAM role attached to this instance.")
    TAGS_NOT_AVAILABLE = CheckWarning(1, "Instance tags metadata is not reachable via IMDS.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that IMDS is responsive and functional."

    def run(self, context: Context) -> Result:
        """Pass when IMDS is responsive, reports an IAM role, and per-user access matches Imds/Secured.

        Responsiveness, a missing IAM role, and per-user access mismatches are failures; an unreachable
        instance tags resource is only a warning, so a check carrying warnings alone is still successful.
        """
        errors: List[CheckFinding] = []
        warnings: List[CheckFinding] = []

        not_responsive = self._check_responsive(context)
        if not_responsive:
            errors.append(not_responsive)
        else:
            # Probe the remaining resources only when IMDS responds at all (nothing to reach otherwise).
            tags_unreachable = self._check_tags(context)
            if tags_unreachable:
                warnings.append(tags_unreachable)
            no_iam_role = self._check_reports_iam_role()
            if no_iam_role:
                errors.append(no_iam_role)

        errors.extend(self._check_per_user_access(context))

        if errors:
            return Result.failure(self, errors=errors, warnings=warnings or None)
        if warnings:
            return Result.warning(self, warnings=warnings)
        return Result.passed(self)

    def _check_responsive(self, context: Context) -> Optional[CheckFinding]:
        """Return a NOT_RESPONSIVE error when the enabled IMDS version does not respond, else None."""
        version = self._imds_version(context)
        return self._probe(imds.list_metadata, version, self.NOT_RESPONSIVE)

    def _check_tags(self, context: Context) -> Optional[CheckFinding]:
        """Return a TAGS_NOT_AVAILABLE warning when the instance tags resource is unreachable, else None."""
        version = self._imds_version(context)
        return self._probe(imds.get_instance_tags, version, self.TAGS_NOT_AVAILABLE)

    def _check_reports_iam_role(self) -> Optional[CheckFinding]:
        """Return a NO_ROLE_FROM_IMDS error when a responsive IMDS reports no IAM role, else None."""
        if imds.get_iam_role_name() is None:
            return self.NO_ROLE_FROM_IMDS
        return None

    def _check_per_user_access(self, context: Context) -> List[CheckFinding]:
        """Return errors when a user's IMDS reachability does not match what Imds/Secured implies."""
        lockdown = self._secured(context) and context.node_type in _LOCKDOWN_NODE_TYPES
        expected = {ROOT_USER: True, CLUSTER_ADMIN_USER: True, SLURM_USER: not lockdown}

        errors: List[CheckFinding] = []
        for user, should_reach in expected.items():
            reachable = imds.is_responsive_for_user(user)
            if reachable and not should_reach:
                errors.append(self.UNEXPECTEDLY_ALLOWED.format(user))
            elif not reachable and should_reach:
                errors.append(self.UNEXPECTEDLY_DENIED.format(user))
        return errors

    @staticmethod
    def _probe(fetch, version, error) -> Optional[CheckFinding]:
        """Run ``fetch(version)``, returning None on success or a formatted CheckFinding on failure."""
        try:
            fetch(version)
            return None
        except Exception as cause:
            logger.error("IMDS probe failed (%s): %s", version, cause)
            return error.format(version)

    @staticmethod
    def _imds_version(context: Context) -> str:
        """Return ImdsSupport from the cluster config, defaulting to IMDSv2 when unset."""
        return ((context.cluster_config or {}).get("Imds") or {}).get("ImdsSupport") or imds.IMDS_V2

    @staticmethod
    def _secured(context: Context) -> bool:
        """Return HeadNode/Imds/Secured from the cluster config, defaulting to True when unset."""
        imds_section = ((context.cluster_config or {}).get("HeadNode") or {}).get("Imds") or {}
        value = imds_section.get("Secured")
        return True if value is None else bool(value)
