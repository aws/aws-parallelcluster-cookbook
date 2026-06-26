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

"""The `run` subcommand.

Runs the applicable diagnostic Checks for the current Context and emits the
resulting Report.
"""

import json
import logging
import os

import click

from pcluster_diag.core.context_builder import ContextBuilder
from pcluster_diag.core.registry import DEFAULT_REGISTRY
from pcluster_diag.core.runner import Runner
from pcluster_diag.models.exceptions import DiagnosticCheckNotPassedError, InsufficientPrivilegesError
from pcluster_diag.models.report import Report
from pcluster_diag.models.result import FAILED_STATUSES
from pcluster_diag.util.serialization import to_dict

logger = logging.getLogger(__name__)


@click.command(name="run")
@click.option(
    "--output-file",
    "output_file",
    type=click.Path(dir_okay=False),
    default=None,
    help="File where the JSON report is written (default: a timestamped file under ./pcluster-diag-output).",
)
@click.option(
    "--yes",
    "-y",
    "assume_yes",
    is_flag=True,
    default=False,
    help="Approve every check that requires confirmation, without prompting.",
)
def run(output_file, assume_yes) -> None:
    """Run the applicable diagnostic checks and emit the report.

    Prints the JSON report to stdout and writes it to a file (best-effort). Progress and errors are
    logged to stderr. Exits 0 only when every check passes; otherwise non-zero.
    """
    _require_root()

    context = ContextBuilder().build()
    all_checks, checks_not_applicable, checks_not_approved = DEFAULT_REGISTRY.select_checks(
        context, assume_yes=assume_yes
    )
    results = Runner().execute(
        context,
        all_checks,
        check_not_applicable=checks_not_applicable,
        check_not_approved=checks_not_approved,
    )
    report = Report(context=context, results=results)

    _emit_report(report, output_file)

    if any(result.status in FAILED_STATUSES for result in results):
        raise DiagnosticCheckNotPassedError()


def _require_root() -> None:
    """Raise InsufficientPrivilegesError unless the process is running as root."""
    if os.geteuid() != 0:
        raise InsufficientPrivilegesError()


def _emit_report(report: Report, output_file) -> None:
    """Write the report file (best-effort) and print the serialized report as JSON to stdout."""
    _write_report_file(report, output_file)
    print(json.dumps(to_dict(report), indent=2))


def _write_report_file(report: Report, output_file) -> None:
    """Write the Report to ``output_file`` (or a default timestamped path) best-effort.

    A write failure is logged but does not abort the run; the report is still printed to stdout.
    """
    path = output_file or report.default_path
    try:
        saved = report.save(path)
        logger.info("Report written to %s", saved)
    except Exception as exc:  # noqa: B902 - best-effort: a write failure must not fail the run
        logger.error("Could not write the JSON report file: %s", exc)
