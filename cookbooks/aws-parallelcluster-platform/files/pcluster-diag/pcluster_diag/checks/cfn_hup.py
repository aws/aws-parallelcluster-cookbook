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

"""Check asserting the cfn-hup daemon's expected state per node type."""

from pcluster_diag.core.constants import CFN_HUP_PROGRAM
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.result import Result
from pcluster_diag.util.services import is_supervisord_program_running


class CfnHupRunsOnlyOnHeadNode(Check):
    """Verify that the cfn-hup daemon runs only on the head node."""

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the cfn-hup daemon runs only on the head node."

    def run(self, context: Context) -> Result:
        """Pass when cfn-hup is running on the head node and stopped elsewhere; fail otherwise."""
        should_be_running = context.node_type is NodeType.HEAD
        is_running = is_supervisord_program_running(CFN_HUP_PROGRAM)
        node_type = context.node_type.value
        if is_running == should_be_running:
            return Result.passed(self)
        if should_be_running:
            message = "{} is not running on the {}.".format(CFN_HUP_PROGRAM, node_type)
        else:
            message = "{} is running on the {}.".format(CFN_HUP_PROGRAM, node_type)
        return Result.failure(self, message=message)
