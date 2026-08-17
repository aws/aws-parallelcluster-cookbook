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

"""Unit tests for the IMDSv2 helper."""

import io
import urllib.error

import pytest
import retrying

from pcluster_diag.util import imds


@pytest.fixture(autouse=True)
def _no_retry_backoff(monkeypatch):
    """Make the retry backoff instant so tests never actually sleep (retrying sleeps internally)."""
    monkeypatch.setattr(retrying.time, "sleep", lambda _seconds: None)


class _FakeResponse:
    def __init__(self, body):
        self._body = body

    def __enter__(self):
        return io.BytesIO(self._body)

    def __exit__(self, *_args):
        return False


def test_get_instance_id_uses_token_then_reads_instance_id(monkeypatch):
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append((request.get_method(), request.full_url, dict(request.header_items())))
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        return _FakeResponse(b"i-0123456789abcdef0\n")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    assert imds.get_instance_id() == "i-0123456789abcdef0"
    # A PUT fetches the token first, then the instance-id GET carries that token.
    assert calls[0][0] == "PUT" and calls[0][1].endswith("/api/token")
    assert calls[1][1].endswith("/meta-data/instance-id")


def test_get_instance_type_uses_token_then_reads_instance_type(monkeypatch):
    calls = []

    def fake_urlopen(request, timeout=None):
        calls.append((request.get_method(), request.full_url, dict(request.header_items())))
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        return _FakeResponse(b"fake.large\n")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    assert imds.get_instance_type() == "fake.large"
    assert calls[0][0] == "PUT" and calls[0][1].endswith("/api/token")
    assert calls[1][1].endswith("/meta-data/instance-type")
    assert calls[1][2]["X-aws-ec2-metadata-token"] == "the-token"


class _FakeCompletedProcess:
    def __init__(self, returncode):
        self.returncode = returncode


def test_is_responsive_for_user_runs_probe_as_user(monkeypatch):
    captured = {}

    def fake_run_command(command, timeout=None, as_user=None):
        captured["command"] = command
        captured["as_user"] = as_user
        return _FakeCompletedProcess(returncode=0)

    monkeypatch.setattr(imds, "run_command", fake_run_command)

    assert imds.is_responsive_for_user("slurm") is True
    # The probe is issued as the target user (run_command drops privileges) as an IMDSv2 token (PUT).
    assert captured["as_user"] == "slurm"
    command = captured["command"]
    assert command[0] == "curl"
    assert "PUT" in command
    assert imds._TOKEN_URL in command


def test_is_responsive_for_user_returns_false_on_connection_refused_without_retrying(monkeypatch):
    # curl exit 7 == the lockdown REJECTed the request: a definitive denial, so no retry happens.
    calls = []

    def fake_run_command(command, timeout=None, as_user=None):
        calls.append(command)
        return _FakeCompletedProcess(returncode=7)

    monkeypatch.setattr(imds, "run_command", fake_run_command)

    assert imds.is_responsive_for_user("slurm") is False
    assert len(calls) == 1


def test_is_responsive_for_user_retries_transient_timeout_then_succeeds(monkeypatch):
    # A transient curl timeout (exit 28) is retried; the next attempt succeeds and the user is reachable.
    returncodes = iter([28, 0])
    calls = []

    def fake_run_command(command, timeout=None, as_user=None):
        calls.append(command)
        return _FakeCompletedProcess(returncode=next(returncodes))

    monkeypatch.setattr(imds, "run_command", fake_run_command)

    assert imds.is_responsive_for_user("pcluster-admin") is True
    assert len(calls) == 2


def test_is_responsive_for_user_gives_up_after_max_attempts_on_persistent_timeout(monkeypatch):
    calls = []

    def fake_run_command(command, timeout=None, as_user=None):
        calls.append(command)
        return _FakeCompletedProcess(returncode=28)

    monkeypatch.setattr(imds, "run_command", fake_run_command)

    assert imds.is_responsive_for_user("pcluster-admin") is False
    assert len(calls) == 3


def test_list_metadata_retries_transient_error_then_succeeds(monkeypatch):
    attempts = {"count": 0}

    def fake_urlopen(request, timeout=None):
        attempts["count"] += 1
        if attempts["count"] == 1:
            raise urllib.error.URLError("timed out")
        return _FakeResponse(b"instance-id\ntags/\n")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    assert imds.list_metadata(imds.IMDS_V1) == "instance-id\ntags/"
    assert attempts["count"] == 2


def test_get_instance_tags_retries_http_error_then_reraises(monkeypatch):
    # The retry is unconditional, so even a definitive 404 is retried up to the attempt limit before
    # propagating (tags not exposed).
    calls = {"count": 0}

    def fake_urlopen(request, timeout=None):
        calls["count"] += 1
        raise urllib.error.HTTPError(request.full_url, 404, "Not Found", hdrs=None, fp=None)

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    with pytest.raises(urllib.error.HTTPError):
        imds.get_instance_tags(imds.IMDS_V1)
    assert calls["count"] == 3


def test_get_reraises_after_exhausting_attempts(monkeypatch):
    calls = {"count": 0}

    def fake_urlopen(request, timeout=None):
        calls["count"] += 1
        raise urllib.error.URLError("timed out")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    with pytest.raises(urllib.error.URLError):
        imds.list_metadata(imds.IMDS_V1)
    assert calls["count"] == 3


def _fake_urlopen_returning(role_body):
    """Return a fake urlopen serving the token first, then ``role_body`` for the credentials listing."""

    def fake_urlopen(request, timeout=None):
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        return _FakeResponse(role_body)

    return fake_urlopen


def test_get_iam_role_name_returns_the_listed_role(monkeypatch):
    monkeypatch.setattr(imds.urllib.request, "urlopen", _fake_urlopen_returning(b"my-instance-role\n"))

    assert imds.get_iam_role_name() == "my-instance-role"


def test_get_iam_role_name_returns_first_when_multiple_listed(monkeypatch):
    monkeypatch.setattr(imds.urllib.request, "urlopen", _fake_urlopen_returning(b"role-a\nrole-b\n"))

    assert imds.get_iam_role_name() == "role-a"


def test_get_iam_role_name_returns_none_on_404(monkeypatch):
    def fake_urlopen(request, timeout=None):
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        raise urllib.error.HTTPError(request.full_url, 404, "Not Found", hdrs=None, fp=None)

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    assert imds.get_iam_role_name() is None


def test_get_iam_role_name_returns_none_when_listing_empty(monkeypatch):
    monkeypatch.setattr(imds.urllib.request, "urlopen", _fake_urlopen_returning(b"\n"))

    assert imds.get_iam_role_name() is None


def test_get_iam_role_name_propagates_non_404_http_errors(monkeypatch):
    def fake_urlopen(request, timeout=None):
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        raise urllib.error.HTTPError(request.full_url, 500, "Server Error", hdrs=None, fp=None)

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    with pytest.raises(urllib.error.HTTPError):
        imds.get_iam_role_name()


def test_get_iam_role_name_retries_transient_timeout_then_succeeds(monkeypatch):
    # A transient timeout on the credentials GET is retried; the next attempt returns the role.
    attempts = {"count": 0}

    def fake_urlopen(request, timeout=None):
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        attempts["count"] += 1
        if attempts["count"] == 1:
            raise urllib.error.URLError("timed out")
        return _FakeResponse(b"my-instance-role\n")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    assert imds.get_iam_role_name() == "my-instance-role"
    assert attempts["count"] == 2


def test_get_iam_role_name_reraises_after_exhausting_attempts(monkeypatch):
    calls = {"count": 0}

    def fake_urlopen(request, timeout=None):
        if request.full_url.endswith("/api/token"):
            return _FakeResponse(b"the-token")
        calls["count"] += 1
        raise urllib.error.URLError("timed out")

    monkeypatch.setattr(imds.urllib.request, "urlopen", fake_urlopen)

    with pytest.raises(urllib.error.URLError):
        imds.get_iam_role_name()
    assert calls["count"] == 3
