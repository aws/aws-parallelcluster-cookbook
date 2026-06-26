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

"""Logging configuration for the CLI."""

import logging
import sys


def configure_logging(level: int = logging.INFO) -> None:
    """Send log records to stderr as ``<timestamp> [<LEVEL>] <logger>: <message>``.

    Configures the root logger, so records from every module logger propagate here. Binds a fresh
    stderr handler each call (resolving ``sys.stderr`` at call time so test runners that replace it are
    still captured) and clears existing root handlers so repeated invocations do not duplicate lines.
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    for handler in list(root_logger.handlers):
        root_logger.removeHandler(handler)
    handler = logging.StreamHandler(stream=sys.stderr)
    handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
    root_logger.addHandler(handler)
