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

"""Model describing the ownership and permissions a filesystem path is expected to have."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ExpectedPathPermissions:
    """The ownership and mode a filesystem path is expected to have on given node types.

    Attributes:
        path: The absolute path to inspect.
        owner: The expected owning user name.
        group: The expected owning group name.
        mode: The expected permission bits as a 4-digit octal string (e.g. ``0755``).
        node_types: The node types the path is expected on; a Check inspects it only on those.
    """

    path: str
    owner: str
    group: str
    mode: str
    node_types: tuple
