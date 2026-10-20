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

"""Report model aggregating the captured Context and per-Check Results."""

import json
import logging
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

from pcluster_diag.core.constants import PACKAGE_NAME
from pcluster_diag.models.context import Context
from pcluster_diag.models.result import Result
from pcluster_diag.util.io_utils import write_text_file
from pcluster_diag.util.serialization import to_json

logger = logging.getLogger(__name__)

# Directory (under a base directory) that holds report files by default.
OUTPUT_DIR_NAME = f"{PACKAGE_NAME}-output"

# Report filename template; the timestamp comes from the Context so file and content always match.
_REPORT_FILENAME_TEMPLATE = f"{PACKAGE_NAME}-report-{{timestamp}}.json"

# Filename template of the details of a check, written next to the report and timestamped like it: the extension is
# txt for details that are text or that JSON cannot represent, json otherwise.
_DETAILS_FILENAME_TEMPLATE = f"{PACKAGE_NAME}-{{check_id}}-{{timestamp}}.{{extension}}"


@dataclass
class Report:
    """The aggregated output of a diagnostics execution: the captured Context plus per-Check Results.

    Attributes:
        context: The Context captured at startup.
        results: The list of per-Check Results produced during the run.
    """

    context: Context
    results: List[Result] = field(default_factory=list)

    @property
    def default_path(self) -> Path:
        """Default report file path: ``<cwd>/<OUTPUT_DIR_NAME>/pcluster-diag-report-<timestamp>.json``.

        The filename embeds this report's context run timestamp, so the file name matches the
        ``timestamp`` recorded inside the report.
        """
        filename = _REPORT_FILENAME_TEMPLATE.format(timestamp=self.context.timestamp)
        return Path(os.getcwd()) / OUTPUT_DIR_NAME / filename

    def save(self, path) -> Path:
        """Write this Report as JSON to ``path``, creating parent directories as needed; return ``path``.

        The details of each check are written to their own file next to the report (see ``_save_details``).
        Errors writing the report propagate to the caller; errors writing the details of a check are logged.
        """
        path = Path(path)
        self._save_details(path)
        write_text_file(path, to_json(self))
        return path

    def _save_details(self, path: Path) -> None:
        """Write the details of each check to ``pcluster-diag-<check id>-<timestamp>.json`` or ``.txt`` by ``path``.

        The details are replaced in the Result by ``details_file``, the absolute path of their file. The report then
        keeps only the current state of each check, while long data such as an update history goes to the separate
        file.

        Details that are a string are written as is to a ``.txt`` file. Other details are written as JSON, with the
        values JSON cannot represent, e.g. datetimes, written as strings; when JSON cannot represent the details at
        all, e.g. with keys that are not strings, they are written as their string to a ``.txt`` file instead.

        The details are removed from the Result even when their file cannot be written, so that the report, and the
        report printed to stdout, never hold them: the Result then has no ``details_file``, and the error is logged.
        A failure to write the details of a check does not prevent writing the details of the others, nor the report.
        """
        for result in self.results:
            if result.details is None:
                continue
            details, result.details = result.details, None
            text, extension = str(details), "txt"
            if not isinstance(details, str):
                try:
                    text, extension = json.dumps(details, indent=2, default=str), "json"
                except (TypeError, ValueError):
                    # Stays as txt file
                    pass
            details_path = path.parent / _DETAILS_FILENAME_TEMPLATE.format(
                check_id=result.check_id, timestamp=self.context.timestamp, extension=extension
            )
            try:
                write_text_file(details_path, text)
            except OSError as error:
                logger.error("Could not write the details of check %s to %s: %s", result.check_id, details_path, error)
                continue
            result.details_file = str(details_path.resolve())
