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

"""Click-based command-line interface.

Defines the `pcluster-diag` command group and registers its subcommands.
"""

import click

from pcluster_diag import __version__
from pcluster_diag.commands.describe_checks import describe_checks
from pcluster_diag.commands.run import run
from pcluster_diag.core.constants import PACKAGE_NAME
from pcluster_diag.core.exception_handler import ExceptionHandler
from pcluster_diag.util.logging_utils import configure_logging


class PclusterDiagGroup(click.Group):
    """A Click group that configures logging and routes any command exception to the ExceptionHandler."""

    def invoke(self, ctx: click.Context):
        """Configure logging, then invoke the selected command, delegating exceptions to the handler."""
        try:
            configure_logging()
            return super().invoke(ctx)
        except Exception as error:  # noqa: BLE001  -- the handler decides how to treat every non-system exception
            ExceptionHandler().handle(error)


@click.group(cls=PclusterDiagGroup)
@click.version_option(__version__, prog_name=PACKAGE_NAME)
def main() -> None:
    """Diagnostics for AWS ParallelCluster nodes."""


main.add_command(run)
main.add_command(describe_checks)


if __name__ == "__main__":
    main()
