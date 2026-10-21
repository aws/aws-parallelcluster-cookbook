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
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch

import pytest

from pcluster_diag.models import report as report_module
from pcluster_diag.models.finding import CheckInfo
from pcluster_diag.models.report import OUTPUT_DIR_NAME
from pcluster_diag.models.result import Result, Status
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


def test_report_save_writes_the_details_of_a_check_to_their_own_file(tmp_path):
    history = [{"time": "2026-10-12T14:02:06+00:00", "outcome": "failed"}]
    result = Result(
        check_id="HistoryCheck",
        check_description="d",
        status=Status.PASSED,
        infos=[CheckInfo(1, "1 update")],
        details=history,
    )
    report = sample_report(results=[result])

    path = report.save(tmp_path / "report.json")

    details_path = tmp_path / "pcluster-diag-HistoryCheck-{}.json".format(report.context.timestamp)
    assert json.loads(details_path.read_text(encoding="utf-8")) == history
    # The report holds the absolute path of the details instead of the details.
    saved_result = json.loads(path.read_text(encoding="utf-8"))["results"][0]
    assert "details" not in saved_result
    assert saved_result["details_file"] == str(details_path.resolve())


def test_report_save_writes_the_report_when_details_cannot_be_written(tmp_path, caplog):
    """A details file that cannot be written is logged and skipped: the other details and the report are written."""
    failing = Result(check_id="FailingCheck", check_description="d", status=Status.PASSED, details=["a"])
    working = Result(check_id="WorkingCheck", check_description="d", status=Status.PASSED, details=["b"])
    report = sample_report(results=[failing, working])
    failing_path = tmp_path / "pcluster-diag-FailingCheck-{}.json".format(report.context.timestamp)
    working_path = tmp_path / "pcluster-diag-WorkingCheck-{}.json".format(report.context.timestamp)
    write_text_file = report_module.write_text_file

    def fake_write_text_file(path, text):
        if Path(path) == failing_path:
            raise OSError("disk full")
        write_text_file(path, text)

    with patch.object(report_module, "write_text_file", side_effect=fake_write_text_file):
        path = report.save(tmp_path / "report.json")

    saved_results = json.loads(path.read_text(encoding="utf-8"))["results"]
    # Neither the report nor the Results hold the details: only the details that were written have a file.
    assert saved_results == [
        {"check_id": "FailingCheck", "check_description": "d", "status": "PASSED"},
        {
            "check_id": "WorkingCheck",
            "check_description": "d",
            "status": "PASSED",
            "details_file": str(working_path.resolve()),
        },
    ]
    assert (failing.details, working.details) == (None, None)
    assert not failing_path.exists()
    assert json.loads(working_path.read_text(encoding="utf-8")) == ["b"]
    assert "Could not write the details of check FailingCheck" in caplog.text


def test_report_save_writes_values_json_cannot_represent_as_strings(tmp_path):
    moment = datetime(2026, 10, 20, 11, 38, 40, tzinfo=timezone.utc)
    result = Result(check_id="TimeCheck", check_description="d", status=Status.PASSED, details=[{"time": moment}])
    report = sample_report(results=[result])

    report.save(tmp_path / "report.json")

    details_path = tmp_path / "pcluster-diag-TimeCheck-{}.json".format(report.context.timestamp)
    assert json.loads(details_path.read_text(encoding="utf-8")) == [{"time": "2026-10-20 11:38:40+00:00"}]


@pytest.mark.parametrize(
    "details, expected_text",
    [
        pytest.param("line 1\nline 2\n", "line 1\nline 2\n", id="string"),
        pytest.param({("q1", "cr1"): "RUNNING"}, "{('q1', 'cr1'): 'RUNNING'}", id="keys json cannot represent"),
    ],
)
def test_report_save_writes_text_details_to_a_text_file(tmp_path, details, expected_text):
    result = Result(check_id="TextCheck", check_description="d", status=Status.PASSED, details=details)
    report = sample_report(results=[result])

    path = report.save(tmp_path / "report.json")

    text_path = tmp_path / "pcluster-diag-TextCheck-{}.txt".format(report.context.timestamp)
    assert text_path.read_text(encoding="utf-8") == expected_text
    assert not (tmp_path / "pcluster-diag-TextCheck-{}.json".format(report.context.timestamp)).exists()
    saved_result = json.loads(path.read_text(encoding="utf-8"))["results"][0]
    assert saved_result["details_file"] == str(text_path.resolve())


def test_best_effort_write_is_enforced_by_caller():
    """The generic writer does not suppress errors, so save() propagates a failing write."""
    report = sample_report()

    with tempfile.TemporaryDirectory() as base_dir:
        with patch("pathlib.Path.write_text", side_effect=OSError("write boom")):
            with pytest.raises(OSError):
                report.save(Path(base_dir) / "report.json")
