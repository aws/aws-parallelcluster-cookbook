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

"""Unit tests for CLI logging configuration."""

import logging

from pcluster_diag.util.logging_utils import configure_logging


def test_configure_logging(capsys):
    # Binds a single stderr handler at the given level.
    configure_logging(level=logging.WARNING)
    root_logger = logging.getLogger()

    assert root_logger.level == logging.WARNING
    assert len(root_logger.handlers) == 1
    assert isinstance(root_logger.handlers[0], logging.StreamHandler)

    # Repeated calls clear prior handlers, so lines are never duplicated (idempotent).
    configure_logging()
    configure_logging()

    assert len(logging.getLogger().handlers) == 1

    # Emits timestamp, level name, and message to stderr.
    logging.getLogger("pcluster_diag.sample").info("hello world")

    captured = capsys.readouterr()
    # Format is "<timestamp> [<LEVEL>] <logger>: <message>", written to stderr.
    assert "[INFO]" in captured.err
    assert "pcluster_diag.sample" in captured.err
    assert "hello world" in captured.err
