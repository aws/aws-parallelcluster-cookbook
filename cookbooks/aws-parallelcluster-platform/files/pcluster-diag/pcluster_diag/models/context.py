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

"""Context model describing the runtime environment a diagnosis runs in."""

from dataclasses import dataclass
from enum import Enum
from typing import Optional


class NodeType(Enum):
    """The type of cluster node the tool is running on."""

    HEAD = "HeadNode"
    COMPUTE = "ComputeFleet"
    LOGIN = "LoginNode"


@dataclass
class Context:
    """The runtime environment captured at CLI startup.

    The builder resolves each value at CLI startup. The instance ids are best-effort: if they cannot
    be determined (e.g. IMDS or AWS raises), they are set to None instead of failing the build.

    Attributes:
        timestamp: When the diagnosis ran, as a UTC string without timezone suffix
            (``YYYY-MM-DDThh-mm-ss``); the same value names the report file.
        pcluster_diag_version: The pcluster-diag package version (``1.0.0`` initially).
        pcluster_version: The installed ParallelCluster version.
        instance_id: The id of the instance the tool is running on, or None if it cannot be determined.
        instance_type: The EC2 instance type the tool runs on (e.g. ``t3.xlarge``), or None if it
            cannot be determined. Used to gate instance-family-specific checks (e.g. the p6+ kefalnd
            version requirement).
        node_type: The node type the tool runs on (HEAD, COMPUTE, or LOGIN).
        cluster_config: The deployed cluster configuration.
        dna_json: The node's ``dna.json`` contents.
        head_node_instance_id: The id of the cluster head node instance, or None if it cannot be determined.
    """

    timestamp: str
    pcluster_diag_version: str
    pcluster_version: str
    instance_id: Optional[str]
    instance_type: Optional[str]
    node_type: NodeType
    cluster_config: dict
    dna_json: dict
    head_node_instance_id: Optional[str]
