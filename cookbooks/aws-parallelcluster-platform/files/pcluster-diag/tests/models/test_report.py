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

"""Unit tests for the Report model: serialization content and file output."""

import json
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

from pcluster_diag.models.report import OUTPUT_DIR_NAME
from pcluster_diag.util.serialization import to_dict
from tests.sample_data import sample_report


@pytest.mark.parametrize(
    "report",
    [
        sample_report(results=[]),
        sample_report(),
    ],
    ids=["empty-results", "mixed-results"],
)
def test_report_serialization_content_per_check(report):
    """The serialized Report carries the context and, per executed Check, its id and Status."""
    serialized = to_dict(report)

    assert serialized["context"]["node_type"] == report.context.node_type.value
    assert len(serialized["results"]) == len(report.results)

    for entry, result in zip(serialized["results"], report.results):
        assert set(entry.keys()) >= {"check_id", "status"}
        # The message field has been removed from Result and must not appear in the serialized output.
        assert "message" not in entry
        assert entry["check_id"] == result.check_id
        assert entry["status"] == result.status.value


def test_report_save_writes_json_to_the_given_path(tmp_path):
    report = sample_report()

    # default_path lives under the CWD's output dir and embeds the context's run timestamp verbatim
    # (the CWD is isolated to tmp_path by the autouse fixture).
    target = report.default_path
    assert target == tmp_path / OUTPUT_DIR_NAME / "pcluster-diag-report-{}.json".format(report.context.timestamp)

    path = report.save(target)

    # The file is written at the exact path (parent dirs created) and contains the serialized Report.
    assert path == target
    assert path.exists()
    saved = json.loads(path.read_text(encoding="utf-8"))
    assert saved == to_dict(report)
    # The report's context carries the same timestamp embedded in the filename.
    assert saved["context"]["timestamp"] == report.context.timestamp


def test_best_effort_write_is_enforced_by_caller():
    """The generic writer does not suppress errors, so save() propagates a failing write."""
    report = sample_report()

    with tempfile.TemporaryDirectory() as base_dir:
        with patch("pathlib.Path.write_text", side_effect=OSError("write boom")):
            with pytest.raises(OSError):
                report.save(Path(base_dir) / "report.json")
