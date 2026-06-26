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

from pcluster_diag.util import imds


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
    assert calls[1][2]["X-aws-ec2-metadata-token"] == "the-token"
