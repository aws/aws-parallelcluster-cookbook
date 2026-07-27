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

from pcluster_diag.models.context import NodeType

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

SLURM_CONF_RELATIVE_PATH = "etc/slurm.conf"

# The supervisord state token that indicates a program is up.
SUPERVISORD_RUNNING_STATE = "RUNNING"

# ParallelCluster management daemons that supervisord must keep RUNNING. cfn-hup is intentionally excluded: it has
# its own dedicated check (CfnHupRunsOnlyOnHeadNode).
NODE_TYPE_EXPECTED_DAEMONS = {
    NodeType.HEAD: ("clustermgtd", "clusterstatusmgtd"),
    NodeType.COMPUTE: ("computemgtd",),
    NodeType.LOGIN: ("loginmgtd",),
}

# clustermgtd writes a heartbeat file that compute nodes read.
DEFAULT_SLURM_INSTALL_DIR = "/opt/slurm"
CLUSTERMGTD_HEARTBEAT_RELATIVE_PATH = "etc/pcluster/.slurm_plugin/clustermgtd_heartbeat"
CLUSTERMGTD_HEARTBEAT_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%f%z"
# Age beyond which the heartbeat is considered stale. Mirrors computemgtd's default clustermgtd_timeout
# (600s): once the heartbeat is older than this, compute nodes treat the head node as offline and can
# self-terminate.
CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS = 600
# Hard cap on reading the heartbeat file. The file may live on a shared/networked filesystem, so a read
# is done via a timed command: hitting this cap means the filesystem is wedged.
CLUSTERMGTD_HEARTBEAT_READ_TIMEOUT_SECONDS = 30

# Directory service
SSSD_CONF_PATH = "/etc/sssd/sssd.conf"
NSS_SLURM_LAUNCH_PARAMETER = "enable_nss_slurm"

DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS = 2.0
DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS = 10.0
# Hard cap so a probe never hangs indefinitely on a stuck directory backend.
DIRECTORY_LOOKUP_COMMAND_TIMEOUT_SECONDS = 30

# FSx / shared-storage diagnostics
# `lfs df -h` must return within this or the filesystem is treated as hanging (server/OST unreachable).
FSX_LFS_DF_TIMEOUT_SECONDS = 30
# `lfs check servers` probes every target, so allow it longer than a plain `lfs df`.
FSX_LFS_CHECK_TIMEOUT_SECONDS = 60
# `lnetctl net show` is a fast, local query; cap it low so a wedged LNet cannot stall the check.
FSX_LNET_SHOW_TIMEOUT_SECONDS = 15
# `lctl get_param` reads client-side import state; bound it so a stuck import cannot hang the check.
FSX_OST_QUERY_TIMEOUT_SECONDS = 30
# `lnetctl ping` over EFA; a hang here is the signal the EFA data path is not working.
FSX_EFA_PING_TIMEOUT_SECONDS = 15
# The StorageType value a FSx for Lustre mount carries in the cluster configuration's SharedStorage.
LUSTRE_STORAGE_TYPE = "FsxLustre"
# NFS-based shared-storage types. Reserved for a future NFS reachability check (a sibling of the Lustre
# checks); not consumed yet.
NFS_STORAGE_TYPES = ("FsxOntap", "FsxOpenZfs", "Efs")
# The osc/mdc import ``state:`` value indicating a reachable, fully-connected target.
HEALTHY_TARGET_STATE = "FULL"
# --- EFA-for-Lustre client parameters -----------------------------------------------------
# TODO/TO-CHECK: every value in this section mirrors the FSx EFA-Lustre client setup, which we cannot
# import. If that setup bumps a version floor, adds/renames a p6+ family, or changes how many EFA devices a
# family binds, re-sync the constants below or these checks will drift and under/over-report. Source:
# https://docs.aws.amazon.com/fsx/latest/LustreGuide/configure-efa-clients.html
#
# The LNet net type for the EFA LND (kefalnd).
EFA_LNET_NET = "efa"
# EFA/RDMA devices surface here; the count is compared against the devices bound to LNet.
EFA_INFINIBAND_SYSFS = "/sys/class/infiniband"
# The EFA driver kernel module (its version gates the EFA-Lustre path).
EFA_DRIVER_KERNEL_MODULE = "efa"
# The kefalnd kernel module (the EFA LND). Its presence is how the setup defines "this Lustre client
# supports EFA" (it verifies that ``modinfo kefalnd`` succeeds), so it is a prerequisite for any
# EFA-for-Lustre probing, checked before the data-path probes run.
EFA_KEFALND_KERNEL_MODULE = "kefalnd"
# Minimum versions the setup enforces before configuring EFA.
MIN_EFA_DRIVER_VERSION = "2.12.1"
MIN_KEFALND_VERSION_P6 = "1.1.1"  # kefalnd floor, enforced on p6+ instances only
MIN_LUSTRE_CLIENT_VERSION = "2.15"
# Instance-family prefixes that require the kefalnd version check (the p6+ families).
P6PLUS_INSTANCE_PREFIXES = ("p6-b200", "p6e-gb200", "p6-b300")

# How many EFA devices the setup binds to LNet, keyed by exact instance type. It binds an
# instance-type-specific SUBSET on some families (not always all devices), so the "expected bound" count is
# this table -- NOT the raw device count. Value semantics:
#   int   -> exactly this many devices are bound (capped at the number actually present)
#   "all" -> all present EFA devices are bound
# An instance type NOT in this table has no static expected count -- either its selection is dynamic
# (e.g. p6e-gb200 binds only host-connected devices, which we cannot count statically) or we have no data
# for it -- so the underbinding check is skipped for it (only a total absence of bound devices is flagged).
EFA_EXPECTED_BOUND_DEVICES = {
    "p5.48xlarge": 8,
    "p5e.48xlarge": 8,
    "p5en.48xlarge": 8,
    "p6-b200.48xlarge": "all",
    "p6-b300.48xlarge": "all",
}
# The systemd oneshot service the FSx EFA-Lustre client setup installs to (re)configure LNet on every
# boot. Its state is the persistence/health signal for this delivery vehicle.
EFA_LUSTRE_SYSTEMD_SERVICE = "configure-efa-fsx-lustre-client.service"

# Slurm accounting
SLURM_ETC_DIR = DEFAULT_SLURM_INSTALL_DIR + "/etc"
SLURMDBD_CONF_PATH = SLURM_ETC_DIR + "/slurmdbd.conf"
SLURM_PARALLELCLUSTER_SLURMDBD_CONF_PATH = SLURM_ETC_DIR + "/slurm_parallelcluster_slurmdbd.conf"
SLURM_STATE_CLUSTERNAME_PATH = SLURM_STATE_SAVE_PATH + "/clustername"
SLURMCTLD_LOG_PATH = "/var/log/slurmctld.log"
SLURMDBD_LOG_PATH = "/var/log/slurmdbd.log"
LOG_SCAN_TAIL_BYTES = 256 * 1024
DEFAULT_SLURMDBD_PORT = 6819  # port slurmdbd LISTENS on (slurm.conf AccountingStoragePort)
DEFAULT_DATABASE_PORT = 3306  # MySQL/MariaDB DATABASE port (Database.Uri; conf StoragePort)
ACCOUNTING_DB_AUTH_TIMEOUT_SECONDS = 10  # hard cap on a credential/auth probe
ACCOUNTING_QUERY_TIMEOUT_SECONDS = 30  # hard cap on a timed end-to-end accounting query
ACCOUNTING_QUERY_LATENCY_WARN_THRESHOLD_SECONDS = 5
ACCOUNTING_QUERY_LATENCY_FAIL_THRESHOLD_SECONDS = 15
SLURMDBD_CONF_OWNER = SLURM_USER
SLURMDBD_CONF_GROUP = SLURM_USER
SLURMDBD_CONF_MODE = "0600"
