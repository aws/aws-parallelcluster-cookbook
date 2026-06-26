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

"""Shared constants."""

# General
PACKAGE_NAME = "pcluster-diag"
TIMESTAMP_FORMAT = "%Y-%m-%dT%H-%M-%S"

# Relevant paths
DEFAULT_DNA_JSON_PATH = "/etc/chef/dna.json"
DEFAULT_CLUSTER_CONFIG_PATH = "/opt/parallelcluster/shared/cluster-config.yaml"
DEFAULT_BOOTSTRAPPED_PATH = "/opt/parallelcluster/.bootstrapped"

# cfn-hup runs as a supervisord program (not a systemd service) managed via the cookbook virtualenv's
# supervisorctl, reading the supervisord config installed by the cookbook.
CFN_HUP_PROGRAM = "cfn-hup"
SUPERVISORCTL_GLOB = "/opt/parallelcluster/pyenv/versions/*/envs/cookbook_virtualenv/bin/supervisorctl"
