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

"""Unit tests for ContextBuilder field population and node-type classification."""

import json
import logging
import re

import pytest

from pcluster_diag import __version__
from pcluster_diag.core.context_builder import ContextBuilder
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.exceptions import ContextBuildError
from tests.sample_data import SAMPLE_HEAD_NODE_INSTANCE_ID, SAMPLE_INSTANCE_ID
from tests.stubs import stub_raising, stub_returning

# Shared node_type token -> NodeType mapping exercised by the classification and build tests.
_NODE_TYPE_CASES = [
    ("HeadNode", NodeType.HEAD),
    ("ComputeFleet", NodeType.COMPUTE),
    ("LoginNode", NodeType.LOGIN),
]


def _write(path, content):
    """Write ``content`` to ``path`` and return the path as a string."""
    path.write_text(content, encoding="utf-8")
    return str(path)


def _builder_from_fixtures(tmp_path, node_type_token="HeadNode", cluster_config=None, pcluster_version="3.11.0"):
    """Build a ContextBuilder pointed at on-disk fixtures under ``tmp_path``."""
    dna = {"cluster": {"node_type": node_type_token, "region": "us-east-1", "stack_name": "test-stack"}}
    config = cluster_config if cluster_config is not None else {"Region": "us-east-1"}
    dna_path = _write(tmp_path / "dna.json", json.dumps(dna))
    # JSON is valid YAML, so this fixture parses whether or not PyYAML is installed.
    config_path = _write(tmp_path / "cluster-config.yaml", json.dumps(config))
    bootstrapped_path = _write(tmp_path / ".bootstrapped", "aws-parallelcluster-cookbook-{}".format(pcluster_version))
    builder = ContextBuilder(
        dna_json_path=dna_path,
        cluster_config_path=config_path,
        bootstrapped_path=bootstrapped_path,
    )
    # Stub the network-backed resolvers (IMDS / CloudFormation) so build() stays offline here.
    builder._instance_id = stub_returning(SAMPLE_INSTANCE_ID)
    builder._head_node_instance_id = stub_returning(SAMPLE_HEAD_NODE_INSTANCE_ID)
    return builder


@pytest.mark.parametrize(
    "token, expected",
    _NODE_TYPE_CASES + [("Mystery", ValueError)],
    ids=["HeadNode", "ComputeFleet", "LoginNode", "unrecognized-raises"],
)
def test_node_type_classification_maps_each_token(token, expected):
    builder = ContextBuilder()

    if isinstance(expected, type) and issubclass(expected, Exception):
        # An unrecognized node_type token is rejected.
        with pytest.raises(expected):
            builder._node_type({"cluster": {"node_type": token}})
    else:
        assert builder._node_type({"cluster": {"node_type": token}}) is expected


@pytest.mark.parametrize(
    "token, expected",
    _NODE_TYPE_CASES,
)
def test_build_classifies_node_type_from_dna_json(tmp_path, token, expected):
    builder = _builder_from_fixtures(tmp_path, node_type_token=token)

    context = builder.build()

    assert context.node_type is expected


def _builder_with_unrecognized_node_type(tmp_path):
    return _builder_from_fixtures(tmp_path, node_type_token="Mystery")


def _builder_with_missing_dna_json(tmp_path):
    builder = _builder_from_fixtures(tmp_path)
    builder._dna_json_path = str(tmp_path / "does-not-exist.json")
    return builder


@pytest.mark.parametrize(
    "make_builder",
    [_builder_with_unrecognized_node_type, _builder_with_missing_dna_json],
    ids=["unrecognized-node-type", "missing-dna-json"],
)
def test_build_fails_with_context_build_error(tmp_path, make_builder):
    # Both an unrecognized node_type token and a missing dna.json cause build() to raise the
    # dedicated ContextBuildError.
    builder = make_builder(tmp_path)

    with pytest.raises(ContextBuildError):
        builder.build()


def test_build_populates_all_context_fields_from_fixtures(tmp_path):
    config = {"Region": "us-east-1"}
    node_type_token = "HeadNode"
    pcluster_version = "3.11.0"
    builder = _builder_from_fixtures(
        tmp_path, node_type_token=node_type_token, cluster_config=config, pcluster_version=pcluster_version
    )

    context = builder.build()

    assert isinstance(context, Context)
    assert context.node_type is NodeType.HEAD
    assert context.pcluster_version == pcluster_version
    assert context.cluster_config == config
    assert context.dna_json["cluster"]["node_type"] == node_type_token
    assert context.instance_id == SAMPLE_INSTANCE_ID
    assert context.head_node_instance_id == SAMPLE_HEAD_NODE_INSTANCE_ID
    # pcluster_diag_version is the installed package version.
    assert context.pcluster_diag_version
    # timestamp is generated at build time as a UTC string in the shared YYYY-MM-DDThh-mm-ss format.
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}", context.timestamp)


_PCLUSTER_VERSION_RAISES = object()


@pytest.mark.parametrize(
    "marker_content, expected",
    [
        ("aws-parallelcluster-cookbook-3.11.0", "3.11.0"),  # version pattern is extracted
        ("bootstrapped", "bootstrapped"),  # no version pattern: raw content is returned
        ("   ", _PCLUSTER_VERSION_RAISES),  # blank marker is rejected
    ],
    ids=["version-pattern", "no-version-pattern", "blank-marker-raises"],
)
def test_pcluster_version_reads_bootstrapped_marker(tmp_path, marker_content, expected):
    builder = _builder_from_fixtures(tmp_path)
    builder._bootstrapped_path = _write(tmp_path / ".bootstrapped-case", marker_content)

    if expected is _PCLUSTER_VERSION_RAISES:
        with pytest.raises(ValueError):
            builder._pcluster_version()
    else:
        assert builder._pcluster_version() == expected


def test_pcluster_diag_version_resolves_to_package_version():
    builder = ContextBuilder()
    # The version comes from the package's __version__ constant (run-from-source, no dist metadata).
    assert builder._pcluster_diag_version() == __version__


def test_instance_id_reads_from_imds(monkeypatch):
    monkeypatch.setattr("pcluster_diag.core.context_builder.imds.get_instance_id", lambda: "i-abc123")

    assert ContextBuilder()._instance_id() == "i-abc123"


def test_head_node_instance_id_reads_stack_output(monkeypatch):
    captured = {}

    def fake_get_stack_output(stack_name, region, output_key):
        captured.update(stack_name=stack_name, region=region, output_key=output_key)
        return "i-headnode"

    monkeypatch.setattr("pcluster_diag.core.context_builder.get_stack_output", fake_get_stack_output)
    dna_json = {"cluster": {"stack_name": "my-stack", "region": "eu-west-1"}}

    # On a non-head node the head node id is read from the cluster stack's HeadNodeInstanceID output.
    assert ContextBuilder()._head_node_instance_id(NodeType.COMPUTE, dna_json) == "i-headnode"
    assert captured == {"stack_name": "my-stack", "region": "eu-west-1", "output_key": "HeadNodeInstanceID"}


def test_head_node_instance_id_on_head_node_returns_current_instance_id(monkeypatch):
    # On the head node the head node id is the current instance id (from IMDS); CloudFormation is never queried.
    monkeypatch.setattr("pcluster_diag.core.context_builder.imds.get_instance_id", lambda: "i-current")

    def _fail(*_args, **_kwargs):
        raise AssertionError("get_stack_output should not be called on the head node")

    monkeypatch.setattr("pcluster_diag.core.context_builder.get_stack_output", _fail)

    result = ContextBuilder()._head_node_instance_id(NodeType.HEAD, {"cluster": {}})

    assert result == "i-current"


def test_instance_id_returns_none_and_logs_on_error(monkeypatch, caplog):
    monkeypatch.setattr("pcluster_diag.core.context_builder.imds.get_instance_id", stub_raising("imds boom"))

    with caplog.at_level(logging.ERROR, logger="pcluster_diag.core.context_builder"):
        result = ContextBuilder()._instance_id()

    # A failure to reach IMDS yields None instead of raising, and is logged at error level.
    assert result is None
    assert any("instance id" in record.getMessage().lower() for record in caplog.records)


def test_head_node_instance_id_returns_none_and_logs_on_error(monkeypatch, caplog):
    monkeypatch.setattr("pcluster_diag.core.context_builder.get_stack_output", stub_raising("aws boom"))
    dna_json = {"cluster": {"stack_name": "my-stack", "region": "eu-west-1"}}

    with caplog.at_level(logging.ERROR, logger="pcluster_diag.core.context_builder"):
        result = ContextBuilder()._head_node_instance_id(NodeType.COMPUTE, dna_json)

    # An AWS failure yields None instead of raising, and is logged at error level.
    assert result is None
    assert any("head node instance id" in record.getMessage().lower() for record in caplog.records)


# --- build() resolution is all-or-nothing --------------------------------------------

# The required Context attributes resolved from the environment, each backed by a resolver method that may fail.
_RESOLVABLE_ATTRIBUTES = [
    "dna_json",
    "cluster_config",
    "node_type",
    "pcluster_version",
    "pcluster_diag_version",
]

# The resolver method on ContextBuilder backing each attribute.
_ATTRIBUTE_METHOD = {
    "dna_json": "_dna_json",
    "cluster_config": "_cluster_config",
    "node_type": "_node_type",
    "pcluster_version": "_pcluster_version",
    "pcluster_diag_version": "_pcluster_diag_version",
}

# A valid value each resolver yields when it is NOT designated as undeterminable.
_VALID_RETURNS = {
    "dna_json": {"cluster": {"node_type": "HeadNode"}},
    "cluster_config": {"Region": "us-east-1"},
    "node_type": NodeType.HEAD,
    "pcluster_version": "3.11.0",
    "pcluster_diag_version": "1.0.0",
}


def _builder_with_failures(failing):
    """Build a ContextBuilder whose resolvers all succeed except those named in ``failing``.

    The best-effort instance-id resolvers are stubbed to fixed values so build() stays offline and
    they never affect the all-or-nothing behavior.
    """
    builder = ContextBuilder()
    for attribute in _RESOLVABLE_ATTRIBUTES:
        if attribute in failing:
            stub = stub_raising("cannot determine {}".format(attribute))
        else:
            stub = stub_returning(_VALID_RETURNS[attribute])
        setattr(builder, _ATTRIBUTE_METHOD[attribute], stub)
    builder._instance_id = stub_returning(SAMPLE_INSTANCE_ID)
    builder._head_node_instance_id = stub_returning(SAMPLE_HEAD_NODE_INSTANCE_ID)
    return builder


@pytest.mark.parametrize(
    "failing",
    [
        set(),
        {"dna_json"},
        {"node_type", "pcluster_version"},
        set(_RESOLVABLE_ATTRIBUTES),
    ],
    ids=["none-fail", "one-fails", "two-fail", "all-fail"],
)
def test_context_build_is_all_or_nothing(failing):
    """build() raises when any required attribute is undeterminable; otherwise returns a fully-resolved Context."""
    builder = _builder_with_failures(failing)

    if failing:
        with pytest.raises(ContextBuildError) as exc_info:
            builder.build()
        # The friendly message carries the underlying cause, naming one of the undeterminable attributes.
        assert any(attribute in str(exc_info.value) for attribute in failing)
    else:
        context = builder.build()
        assert isinstance(context, Context)
        assert context.node_type is _VALID_RETURNS["node_type"]
        assert context.pcluster_version == _VALID_RETURNS["pcluster_version"]
        assert context.cluster_config == _VALID_RETURNS["cluster_config"]
        assert context.dna_json == _VALID_RETURNS["dna_json"]
        assert context.pcluster_diag_version == _VALID_RETURNS["pcluster_diag_version"]
        assert context.instance_id == SAMPLE_INSTANCE_ID
        assert context.head_node_instance_id == SAMPLE_HEAD_NODE_INSTANCE_ID
