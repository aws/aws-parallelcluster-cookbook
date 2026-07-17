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

"""Check asserting the IAM role IMDS reports matches the role recorded in the cfn-hup config.

cfn-hup calls CloudFormation using the role named on the ``role=`` line of ``/etc/cfn/cfn-hup.conf``,
retrieving its credentials from IMDS by that name. If the instance's attached role is changed out of band
(e.g. a new instance profile) without updating that file, IMDS no longer exposes the old role name and
cfn-hup's credential lookup returns 404, so cluster updates driven by cfn-hup fail.
"""

import configparser

from pcluster_diag.core.constants import CFN_HUP_CONF_PATH
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.util import imds


class ImdsRoleMatchesCfnHupConfig(Check):
    """Verify the IAM role IMDS reports matches the ``role=`` recorded in ``/etc/cfn/cfn-hup.conf``.

    cfn-hup runs only on the head node, so this check applies there. A mismatch means the instance's
    attached role was changed without updating the cfn-hup config, which breaks cfn-hup's credential
    retrieval from IMDS.
    """

    NO_ROLE_CONFIGURED = CheckError(1, "No 'role' is set in {}.")
    NO_ROLE_FROM_IMDS = CheckError(2, "IMDS reports no IAM role attached to this instance.")
    ROLE_MISMATCH = CheckError(
        3,
        "The IAM role reported by IMDS ('{}') does not match the role configured in {} ('{}'); "
        "make sure they match.",
    )

    def __init__(self, cfn_hup_conf_path: str = CFN_HUP_CONF_PATH) -> None:
        """Create the Check, optionally overriding the cfn-hup config path (used by tests)."""
        self._cfn_hup_conf_path = cfn_hup_conf_path

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the IAM role returned by IMDS matches the role configured in cfn-hup.conf."

    def should_run(self, context: Context) -> bool:
        """Run only on the head node, where cfn-hup and its config file live."""
        return context.node_type is NodeType.HEAD

    def run(self, context: Context) -> Result:
        """Pass when the cfn-hup ``role=`` matches the role IMDS reports; fail on a mismatch or if absent."""
        configured_role = self._read_configured_role()
        if configured_role is None:
            return Result.failure(self, errors=[self.NO_ROLE_CONFIGURED.format(self._cfn_hup_conf_path)])

        imds_role = imds.get_iam_role_name()
        if imds_role is None:
            return Result.failure(self, errors=[self.NO_ROLE_FROM_IMDS])

        if imds_role != configured_role:
            return Result.failure(
                self,
                errors=[self.ROLE_MISMATCH.format(imds_role, self._cfn_hup_conf_path, configured_role)],
            )

        return Result.passed(self)

    def _read_configured_role(self):
        """Return the ``role`` under the cfn-hup config's ``[main]`` section, or None if unset.

        Raises:
            FileNotFoundError: If the cfn-hup config file does not exist (mapped to a CHECK_ERROR by the Runner).
        """
        # interpolation=None keeps ``%`` in values (e.g. url-encoded arns) literal; strict=False tolerates
        # a hand-edited file with a repeated key by taking the last value.
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        with open(self._cfn_hup_conf_path, encoding="utf-8") as config_file:
            parser.read_file(config_file)
        if not parser.has_option("main", "role"):
            return None
        role = parser.get("main", "role").strip()
        return role or None
