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

"""Unit tests for reading a log with its rotated copy."""

import pytest

from pcluster_diag.util import log_files


def test_read_rotated_log_reads_the_rotated_copy_first(tmp_path):
    log = tmp_path / "chef-client.log"
    (tmp_path / "chef-client.log.1").write_text("old\n")
    log.write_text("new\n")

    assert list(log_files.read_rotated_log(str(log))) == ["old", "new"]


def test_read_rotated_log_skips_missing_files(tmp_path):
    log = tmp_path / "chef-client.log"
    log.write_text("only\n")

    assert list(log_files.read_rotated_log(str(log))) == ["only"]


def test_read_rotated_log_raises_when_the_log_does_not_exist_even_with_a_rotated_copy(tmp_path):
    (tmp_path / "chef-client.log.1").write_text("old\n")

    with pytest.raises(FileNotFoundError, match="chef-client.log"):
        log_files.read_rotated_log(str(tmp_path / "chef-client.log"))


def test_read_rotated_log_raises_when_no_file_exists(tmp_path):
    with pytest.raises(FileNotFoundError, match="missing.log"):
        log_files.read_rotated_log(str(tmp_path / "missing.log"))
