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

"""Unit tests for the generic file I/O utility layer."""

import pytest

from pcluster_diag.util.io_utils import write_text_file

_TEXT = '{"hello": "world"}'


@pytest.mark.parametrize(
    "rel_path, nested",
    [("report.json", False), ("nested/dir/report.json", True)],
    ids=["flat-target", "nested-target-creates-parents"],
)
def test_write_text_file_writes_content(tmp_path, rel_path, nested):
    target = tmp_path / rel_path
    if nested:
        # Missing parent directories are created on demand before the file is written.
        assert not target.parent.exists()

    write_text_file(target, _TEXT)

    if nested:
        assert target.parent.is_dir()
    assert target.read_text(encoding="utf-8") == _TEXT


def _target_blocked_by_file_parent(tmp_path):
    # A regular file sits where a parent directory would need to be created.
    blocker = tmp_path / "not-a-dir"
    blocker.write_text("x", encoding="utf-8")
    return blocker / "report.json"


def _target_is_a_directory(tmp_path):
    # A directory cannot be opened for text writing.
    target = tmp_path / "a-directory"
    target.mkdir()
    return target


@pytest.mark.parametrize(
    "make_target",
    [_target_blocked_by_file_parent, _target_is_a_directory],
    ids=["parent-is-a-file", "target-is-a-directory"],
)
def test_write_text_file_propagates_os_errors(tmp_path, make_target):
    # IsADirectoryError and PermissionError are subclasses of OSError, so this covers both.
    target = make_target(tmp_path)

    with pytest.raises(OSError):
        write_text_file(target, _TEXT)
