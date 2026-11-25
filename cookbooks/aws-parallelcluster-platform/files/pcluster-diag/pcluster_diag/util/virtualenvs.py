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

"""Helpers for locating the ParallelCluster Python virtualenvs installed on the node."""

import glob

from pcluster_diag.core.constants import BASE_DIR

# The node virtualenv's bin directory, holding the node package entry points (e.g. the Slurm resume/suspend
# hooks); mirrors the cookbook's node_virtualenv_path.
NODE_VIRTUALENV_BIN_GLOB = BASE_DIR + "/pyenv/versions/*/envs/node_virtualenv/bin"


def node_virtualenv_bin() -> str:
    """Return the ``bin`` directory of the node virtualenv (e.g. holding the Slurm resume/suspend hooks).

    Raises:
        FileNotFoundError: If the node virtualenv cannot be located.
    """
    matches = sorted(glob.glob(NODE_VIRTUALENV_BIN_GLOB))
    if not matches:
        raise FileNotFoundError(
            "Could not locate the node virtualenv (looked in '{}').".format(NODE_VIRTUALENV_BIN_GLOB)
        )
    return matches[0]
