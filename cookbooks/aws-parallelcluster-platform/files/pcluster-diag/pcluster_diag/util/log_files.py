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

"""Read a log together with the single rotated copy logrotate keeps of it, one line at a time.

The logs of a long-living cluster can be large: they are streamed, so that the parsers only keep in memory the lines
they need.
"""

import errno
import os
from typing import Iterator, List

from pcluster_diag.core.constants import ROTATED_LOG_SUFFIX


def read_rotated_log(path: str) -> Iterator[str]:
    """Return an iterator over the lines of the rotated copy of ``path``, then of ``path``, without newlines.

    The files are read one line at a time while iterating. The rotated copy is optional: it is skipped if it does
    not exist when called, e.g. for a log that was never rotated. Any error reading a file, including a file that
    disappeared since the call, is raised while iterating.

    Raises:
        FileNotFoundError: If ``path`` does not exist, when called.
    """
    if not os.path.exists(path):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), path)
    rotated_path = path + ROTATED_LOG_SUFFIX
    paths = [rotated_path, path] if os.path.exists(rotated_path) else [path]
    return _lines(paths)


def _lines(paths: List[str]) -> Iterator[str]:
    """Yield the lines of the files in ``paths``, one after the other, without newlines."""
    for file_path in paths:
        with open(file_path, encoding="utf-8", errors="replace") as log_file:
            for line in log_file:
                yield line.rstrip("\n")
