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

"""Unit tests for the Lustre-specific helpers: lfs df parsing and client detection."""

from pcluster_diag.util import kernel_module, lustre
from tests.test_helpers import DEGRADED_LFS_DF as _DEGRADED_LFS_DF
from tests.test_helpers import HEALTHY_LFS_DF as _HEALTHY_LFS_DF
from tests.test_helpers import completed_process as _completed

# --- lfs df -h parsing ----------------------------------------------------------------


def test_parse_lfs_df_healthy_all_targets_available():
    targets = lustre.parse_lfs_df(_HEALTHY_LFS_DF)

    assert [t.uuid for t in targets] == [
        "fs-abc-MDT0000_UUID",
        "fs-abc-OST0000_UUID",
        "fs-abc-OST0001_UUID",
    ]
    assert all(t.available for t in targets)
    assert [t.role for t in targets] == ["MDT", "OST", "OST"]


def test_unavailable_targets_flags_errored_target():
    unavailable = lustre.unavailable_targets(_DEGRADED_LFS_DF)

    assert [t.uuid for t in unavailable] == ["fs-abc-OST0001_UUID"]
    assert unavailable[0].role == "OST"
    assert "Resource temporarily unavailable" in unavailable[0].detail


def test_unavailable_targets_empty_when_all_healthy():
    assert lustre.unavailable_targets(_HEALTHY_LFS_DF) == []


def test_parse_lfs_df_ignores_header_and_summary():
    targets = lustre.parse_lfs_df(_HEALTHY_LFS_DF)

    assert all("filesystem_summary" not in t.uuid and t.uuid != "UUID" for t in targets)


def test_parse_lfs_df_skips_non_target_lines():
    # A body line that is neither a capacity row nor names a target role is ignored.
    assert lustre.parse_lfs_df("some random note line\n\n") == []


def test_parse_lfs_df_skips_single_token_line():
    # A body line with fewer than two tokens is not a parseable target row.
    assert lustre.parse_lfs_df("loneword\n") == []


# --- Lustre client version (delegates to util.kernel_module) -------------------------------


def test_lustre_client_version_from_modinfo(monkeypatch):
    monkeypatch.setattr(kernel_module, "run_command", lambda command: _completed(stdout="2.15.6\n"))

    assert lustre.lustre_client_version() == "2.15.6"


def test_lustre_client_version_none_on_failure(monkeypatch):
    monkeypatch.setattr(kernel_module, "run_command", lambda command: _completed(returncode=1))

    assert lustre.lustre_client_version() is None
