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

"""Unit tests for the virtualenv location helpers."""

import pytest

from pcluster_diag.util import virtualenvs

_NODE_BIN = "/opt/parallelcluster/pyenv/versions/3.12.11/envs/node_virtualenv/bin"


def test_node_virtualenv_bin(monkeypatch):
    monkeypatch.setattr(virtualenvs.glob, "glob", lambda _pattern: [_NODE_BIN])

    assert virtualenvs.node_virtualenv_bin() == _NODE_BIN


def test_node_virtualenv_bin_raises_when_missing(monkeypatch):
    monkeypatch.setattr(virtualenvs.glob, "glob", lambda _pattern: [])

    with pytest.raises(FileNotFoundError, match="node_virtualenv"):
        virtualenvs.node_virtualenv_bin()
