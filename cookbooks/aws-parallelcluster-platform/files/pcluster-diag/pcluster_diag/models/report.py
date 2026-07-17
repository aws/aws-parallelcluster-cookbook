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

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

from pcluster_diag.core.constants import PACKAGE_NAME
from pcluster_diag.models.context import Context
from pcluster_diag.models.result import Result
from pcluster_diag.util.io_utils import write_text_file
from pcluster_diag.util.serialization import to_json

# Directory (under a base directory) that holds report files by default.
OUTPUT_DIR_NAME = f"{PACKAGE_NAME}-output"

# Report filename template; the timestamp comes from the Context so file and content always match.
_REPORT_FILENAME_TEMPLATE = f"{PACKAGE_NAME}-report-{{timestamp}}.json"


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

        Write errors propagate to the caller.
        """
        path = Path(path)
        write_text_file(path, to_json(self))
        return path
