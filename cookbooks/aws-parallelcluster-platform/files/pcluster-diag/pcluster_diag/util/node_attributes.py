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

"""Reader of the node attributes the cookbook dumped to /etc/chef/node_attributes.json."""

import json
from pathlib import Path
from typing import Any, Optional

from pcluster_diag.core.constants import NODE_ATTRIBUTES_PATH, NODE_ATTRIBUTES_PRECEDENCE


def load_node_attributes(path: str = NODE_ATTRIBUTES_PATH) -> dict:
    """Return the node attributes in ``path``, with the precedence levels merged as Chef merges them.

    The file is a serialized Chef node, which keeps each precedence level apart (``default``, ``normal``,
    ``override``, ``automatic``). They are deep-merged in precedence order, as the InSpec tests do.

    Raises:
        OSError: If the file cannot be read.
        ValueError: If the file is not a JSON object.
    """
    content = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(content, dict):
        raise ValueError("{} does not hold a JSON object".format(path))
    merged: dict = {}
    for level in NODE_ATTRIBUTES_PRECEDENCE:
        merged = _deep_merge(merged, content.get(level) or {})
    return merged


def attribute(attributes: dict, *keys: str) -> Optional[Any]:
    """Return the attribute at the path ``keys`` in ``attributes``, or None if any key along the path is missing."""
    value: Any = attributes
    for key in keys:
        if not isinstance(value, dict) or key not in value:
            return None
        value = value[key]
    return value


def _deep_merge(base: dict, other: dict) -> dict:
    """Return ``base`` updated with ``other``, merging nested dicts rather than replacing them."""
    merged = dict(base)
    for key, value in other.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged
