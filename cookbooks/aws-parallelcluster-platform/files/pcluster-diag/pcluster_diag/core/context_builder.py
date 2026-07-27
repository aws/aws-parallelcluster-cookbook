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

"""Construction of the runtime diagnostic Context."""

import json
import logging
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import yaml

from pcluster_diag import __version__
from pcluster_diag.core.constants import (
    DEFAULT_BOOTSTRAPPED_PATH,
    DEFAULT_CLUSTER_CONFIG_PATH,
    DEFAULT_DNA_JSON_PATH,
    TIMESTAMP_FORMAT,
)
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.exceptions import ContextBuildError
from pcluster_diag.util import imds
from pcluster_diag.util.cfn import get_stack_output

logger = logging.getLogger(__name__)


class ContextBuilder:
    """Builds a fully-resolved Context describing the runtime environment."""

    def __init__(
        self,
        dna_json_path: str = DEFAULT_DNA_JSON_PATH,
        cluster_config_path: str = DEFAULT_CLUSTER_CONFIG_PATH,
        bootstrapped_path: str = DEFAULT_BOOTSTRAPPED_PATH,
    ) -> None:
        """Create a builder, optionally overriding the read-only source paths (used by tests)."""
        self._dna_json_path = dna_json_path
        self._cluster_config_path = cluster_config_path
        self._bootstrapped_path = bootstrapped_path

    def build(self) -> Context:
        """Resolve every attribute via its helper and return a fully-resolved Context.

        Construction is all-or-nothing: if any helper fails, no Context is produced and a
        ContextBuildError is raised carrying a user-facing message and the underlying cause.
        """
        try:
            dna_json = self._dna_json()
            node_type = self._node_type(dna_json)
            instance_id = self._instance_id()
            return Context(
                timestamp=datetime.now(timezone.utc).strftime(TIMESTAMP_FORMAT),
                pcluster_diag_version=self._pcluster_diag_version(),
                pcluster_version=self._pcluster_version(),
                instance_id=instance_id,
                instance_type=self._instance_type(),
                node_type=node_type,
                cluster_config=self._cluster_config(),
                dna_json=dna_json,
                head_node_instance_id=self._head_node_instance_id(node_type, dna_json),
            )
        except Exception as error:  # any failure means the Context cannot be built
            raise ContextBuildError(
                "Failed to build the diagnostic context. pcluster-diag is meant to run on an AWS ParallelCluster node. "
                "This failure most likely means it is not running on a cluster node. "
                "Underlying error: {}".format(error)
            ) from error

    def _pcluster_diag_version(self) -> str:
        """Return the pcluster-diag version declared in the package."""
        return __version__

    def _pcluster_version(self) -> str:
        """Read the ParallelCluster version from the node's bootstrapped marker file."""
        content = Path(self._bootstrapped_path).read_text(encoding="utf-8").strip()
        match = re.search(r"\d+\.\d+\.\d+", content)
        if match:
            return match.group(0)
        if not content:
            raise ValueError("bootstrapped marker is empty")
        return content

    def _instance_id(self) -> Optional[str]:
        """Return the current instance id from IMDS, or None (logging an error) if it cannot be determined."""
        try:
            return imds.get_instance_id()
        except Exception as error:  # best-effort: a failure must not abort the build
            logger.error("Could not determine the current instance id from IMDS: %s", error)
            return None

    def _instance_type(self) -> Optional[str]:
        """Return the current instance type from IMDS, or None (logging an error) if it cannot be determined.

        The instance type is not carried in dna.json (neither the head-node nor the compute-node cluster
        dict includes it), so it is resolved from IMDS -- the same source the official EFA-Lustre config
        script uses. Best-effort: a failure must not abort the build.
        """
        try:
            return imds.get_instance_type()
        except Exception as error:
            logger.error("Could not determine the current instance type from IMDS: %s", error)
            return None

    def _node_type(self, dna_json: dict) -> NodeType:
        """Classify the node type from ``dna.json``; the token is the NodeType member value."""
        raw = ((dna_json or {}).get("cluster") or {}).get("node_type")
        return NodeType(raw)

    def _cluster_config(self) -> dict:
        """Read and parse the deployed cluster configuration (YAML)."""
        return yaml.safe_load(Path(self._cluster_config_path).read_text(encoding="utf-8"))

    def _dna_json(self) -> dict:
        """Read and parse the node's ``dna.json`` into a dict."""
        return json.loads(Path(self._dna_json_path).read_text(encoding="utf-8"))

    def _head_node_instance_id(self, node_type: NodeType, dna_json: dict) -> Optional[str]:
        """Return the head node instance id.

        On the head node it is the current instance id; on any other node it is read from the cluster
        stack's ``HeadNodeInstanceID`` output, returning None (logging an error) if that cannot be done.
        """
        if node_type is NodeType.HEAD:
            return self._instance_id()
        try:
            cluster = (dna_json or {}).get("cluster") or {}
            return get_stack_output(cluster["stack_name"], cluster["region"], "HeadNodeInstanceID")
        except Exception as error:  # best-effort: a failure must not abort the build
            logger.error("Could not determine the head node instance id from CloudFormation: %s", error)
            return None
