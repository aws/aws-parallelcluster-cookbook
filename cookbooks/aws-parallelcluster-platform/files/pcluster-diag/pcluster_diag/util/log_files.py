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

"""Read a log together with the single rotated copy logrotate keeps of it."""

from typing import List, Tuple

from pcluster_diag.core.constants import ROTATED_LOG_SUFFIX


def read_rotated_log(path: str) -> Tuple[List[str], List[str]]:
    """Return the lines of ``path`` and of its rotated copy, oldest first, and the files they were read from.

    A file that does not exist is skipped; any other error reading a file is raised.
    """
    lines: List[str] = []
    files: List[str] = []
    for file_path in (path + ROTATED_LOG_SUFFIX, path):
        try:
            with open(file_path, encoding="utf-8", errors="replace") as log_file:
                lines.extend(log_file.read().splitlines())
        except FileNotFoundError:
            continue
        files.append(file_path)
    return lines, files
