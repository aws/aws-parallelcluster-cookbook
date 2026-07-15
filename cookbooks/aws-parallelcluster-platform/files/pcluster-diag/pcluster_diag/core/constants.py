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

# Relevant paths. The base and shared directories mirror the cookbook attributes
# base_dir and shared_dir (see cookbooks/aws-parallelcluster-shared/attributes/cluster.rb);
# they are not exposed in dna.json, so they are reproduced here.
BASE_DIR = "/opt/parallelcluster"
SHARED_DIR = BASE_DIR + "/shared"
DEFAULT_DNA_JSON_PATH = "/etc/chef/dna.json"
DEFAULT_CLUSTER_CONFIG_PATH = SHARED_DIR + "/cluster-config.yaml"
DEFAULT_BOOTSTRAPPED_PATH = BASE_DIR + "/.bootstrapped"

# Written by clusterstatusmgtd (running as the cluster admin user) to drive compute-fleet status
# transitions; mirrors the cookbook attribute computefleet_status_path.
COMPUTEFLEET_STATUS_PATH = SHARED_DIR + "/computefleet-status.json"

# The munge authentication key.
MUNGE_KEY_PATH = "/etc/munge/munge.key"

# Slurm's StateSaveLocation directory.
SLURM_STATE_SAVE_PATH = "/var/spool/slurm.state"

# cfn-hup runs as a supervisord program (not a systemd service) managed via the cookbook virtualenv's
# supervisorctl, reading the supervisord config installed by the cookbook.
CFN_HUP_PROGRAM = "cfn-hup"
SUPERVISORCTL_GLOB = "/opt/parallelcluster/pyenv/versions/*/envs/cookbook_virtualenv/bin/supervisorctl"

# The cfn-hup config on the head node. Its ``role=`` names the IAM role cfn-hup uses to fetch
# credentials from IMDS, which must match the role IMDS reports for the instance.
CFN_HUP_CONF_PATH = "/etc/cfn/cfn-hup.conf"

# Reserved users and groups, with the ids ParallelCluster assigns them (derived from a base of 400).
# See cookbooks/aws-parallelcluster-shared/attributes/users.rb.
ROOT_USER = "root"
CLUSTER_ADMIN_USER = "pcluster-admin"
CLUSTER_ADMIN_GROUP = "pcluster-admin"
SLURM_USER = "slurm"
MUNGE_USER = "munge"
SLURM_SHARE_GROUP = "pcluster-slurm-share"

RESERVED_BASE_UID = 400

RESERVED_USER_IDS = {
    CLUSTER_ADMIN_USER: RESERVED_BASE_UID,
    SLURM_USER: RESERVED_BASE_UID + 1,
    MUNGE_USER: RESERVED_BASE_UID + 2,
}

RESERVED_GROUP_IDS = {
    CLUSTER_ADMIN_GROUP: RESERVED_BASE_UID,
    SLURM_USER: RESERVED_BASE_UID + 1,
    MUNGE_USER: RESERVED_BASE_UID + 2,
    SLURM_SHARE_GROUP: RESERVED_BASE_UID + 5,
}
