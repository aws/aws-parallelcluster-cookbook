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

"""Check asserting ParallelCluster's reserved POSIX users and groups exist and own their id alone.

A reserved id shared with a pre-existing account is a real, hard-to-diagnose failure mode: when
ParallelCluster's ``pcluster-admin`` shares its uid with another ``/etc/passwd`` entry, ``su`` and sudo
resolve the uid to whichever name comes first, so the daemons that rely on ``pcluster-admin``'s NOPASSWD
sudoers rules silently run as the wrong user and lose their privileges.
"""

from pcluster_diag.core.constants import RESERVED_GROUP_IDS, RESERVED_USER_IDS
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.util import users


class ReservedUsersAndGroups(Check):
    """Verify each reserved ParallelCluster user and group exists and does not share its id."""

    MISSING = CheckError(1, "{} '{}' does not exist.")
    SHARED_ID = CheckError(2, "{} '{}' shares id {} with: {}.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that reserved ParallelCluster users and groups exist and do not share their uid/gid."

    def run(self, context: Context) -> Result:
        """Pass when every reserved user and group exists and owns its id alone; fail listing each problem."""
        errors = []
        errors.extend(self._check("user", RESERVED_USER_IDS, users.get_user_uid, users.get_usernames_for_uid))
        errors.extend(self._check("group", RESERVED_GROUP_IDS, users.get_group_gid, users.get_groupnames_for_gid))
        if errors:
            return Result.failure(self, errors=errors)
        return Result.passed(self)

    def _check(self, kind, reserved_ids, get_id, get_names_for_id):
        """Return the errors for one entity kind (``user`` or ``group``): missing entries and shared ids."""
        errors = []
        for name in reserved_ids:
            actual_id = get_id(name)
            if actual_id is None:
                errors.append(self.MISSING.format(kind, name))
                continue
            others = [other for other in get_names_for_id(actual_id) if other != name]
            if others:
                errors.append(self.SHARED_ID.format(kind, name, actual_id, ", ".join(others)))
        return errors
