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

"""Check asserting the cfn-hup daemon runs only on the head node and it is properly configured."""

from pcluster_diag.core.constants import CFN_HUP_CONF_PATH, CFN_HUP_PROGRAM, MISSING_VALUE
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.util import imds
from pcluster_diag.util.io_utils import read_ini_option
from pcluster_diag.util.services import is_supervisord_program_running


class CfnHup(Check):
    """Verify the cfn-hup daemon runs only on the head node and it is properly configured.

    Two concerns are checked:

    - Daemon location (every node type): cfn-hup must be RUNNING on the head node and stopped everywhere
      else.
    - Configuration (head node only): cfn-hup calls CloudFormation using the role named on the ``role=``
      line of ``/etc/cfn/cfn-hup.conf``, retrieving its credentials from IMDS by that name. That role must
      match the role IMDS actually reports, otherwise cfn-hup's credential lookup returns 404 and
      cfn-hup-driven cluster updates fail; a role left unset in the config counts as a mismatch. (IMDS
      reporting no role at all is surfaced by the Imds check.)
    """

    NOT_RUNNING_ON_HEAD_NODE = CheckError(1, "{} is not running on the head node.".format(CFN_HUP_PROGRAM))
    RUNNING_ON_NON_HEAD_NODE = CheckError(2, "{} is running on a non-head node.".format(CFN_HUP_PROGRAM))
    ROLE_MISMATCH = CheckError(3, "The IAM role reported by IMDS ('{}') does not match the one in {} ('{}').")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the cfn-hup daemon runs only on the head node and it is properly configured."

    def run(self, context: Context) -> Result:
        """Report every cfn-hup problem: wrong daemon location or, on the head node, a bad configured role."""
        errors = self._check_daemon_location(context)
        if context.node_type is NodeType.HEAD:
            errors.extend(self._check_config_role())
        return Result.from_findings(self, errors=errors)

    def _check_daemon_location(self, context: Context):
        """Return the daemon-location errors: cfn-hup must run on the head node and be stopped elsewhere."""
        should_be_running = context.node_type is NodeType.HEAD
        is_running = is_supervisord_program_running(CFN_HUP_PROGRAM)
        if is_running == should_be_running:
            return []
        return [self.NOT_RUNNING_ON_HEAD_NODE if should_be_running else self.RUNNING_ON_NON_HEAD_NODE]

    def _check_config_role(self):
        """Return a ROLE_MISMATCH error when cfn-hup's configured role differs from the role IMDS reports.

        A cfn-hup.conf with no ``role=`` line is reported as a mismatch whose configured value is
        ``<missing>``. IMDS reporting no role at all is the Imds check's concern, so it is not flagged here.

        Raises:
            FileNotFoundError: If the cfn-hup config file does not exist (mapped to a CHECK_ERROR by the Runner).
        """
        configured_role = read_ini_option(CFN_HUP_CONF_PATH, "main", "role")

        imds_role = imds.get_iam_role_name()
        if imds_role is None:
            return []

        if imds_role != configured_role:
            return [self.ROLE_MISMATCH.format(imds_role, CFN_HUP_CONF_PATH, configured_role or MISSING_VALUE)]

        return []
