aws-parallelcluster-cookbook CHANGELOG
======================================

This file is used to list changes made in each version of the AWS ParallelCluster cookbook.

2.6.2
-----

**ENHANCEMENTS**

**CHANGES**
- Upgrade EFA installer to version 1.8.4
  - Kernel module: efa-1.5.1 (no change)
  - RDMA core: rdma-core-25.0 (distributed only) (no change)
  - Libfabric: libfabric-aws-1.9.0amzn1.1 (no change)
  - Open MPI: openmpi40-aws-4.0.3 (updated from openmpi40-aws-4.0.2)
  - EFA profile: efa-profile-1.0 (new)
    - Configures $PATH and ld config bits for Libfabric and Open MPI installed by EFA
  - EFA config: efa-config-1.0 (new)
    - Configures hugepages, system limits, and paths for Libfabric and Open MPI installed by EFA

**BUG FIXES**

2.6.1
-----

**ENHANCEMENTS**
- Change ProctrackType from proctrack/gpid to proctrack/cgroup in slurm.conf in order to better handle termination of
  stray processes when running MPI applications. This also includes the creation of a cgroup Slurm configuration in
  in order to enable the cgroup plugin.
- Skip execution, at node bootstrap time, of all those install recipes that are already applied at AMI creation time.
  The old behaviour can be restored setting the property "skip_install_recipes" to "no" through extra_json. The old 
  behaviour is required in case a custom_node_package is specified and could be needed in case custom_cookbook is used
  (depending or not if the custom cookbook contains changes into any *_install recipes)
- Start CloudWatch agent earlier in the node bootstrapping phase so that cookbook execution failures are correctly
  uploaded and are available for troubleshooting.

**CHANGES**
- FSx Lustre: remove `x-systemd.requires=lnet.service` from mount options in order to rely on default lnet setup
  provided by Lustre.
- Enforce Packer version to be >= 1.4.0 when building an AMI. This is also required for customers using `pcluster 
  createami` command.
- Remove /tmp/proxy.sh file. Proxy configuration is now written into /etc/profile.d/proxy.sh
- Omit cfn-init-cmd and cfn-wire from the files stored in CloudWatch logs.

**BUG FIXES**
- Fix installation of Intel Parallel Studio XE Runtime that requires yum4 since version 2019.5.
- Fix compilation of Torque scheduler on Ubuntu 18.04.


2.6.0
-----

**ENHANCEMENTS**
- Add support for Amazon Linux 2
- Install NICE DCV on Ubuntu 18.04 (this includes ubuntu-desktop, lightdm, mesa-util packages)
- Install and setup Amazon Time Sync on all OSs
- Compile Slurm with mysql accounting plugin on Ubuntu 18.04 and Ubuntu 16.04
- Enable FSx Lustre on Ubuntu 18.04 and Ubuntu 16.04

**CHANGES**
- Upgrade EFA installer to version 1.8.3:
  - Kernel module: efa-1.5.1 (updated from efa-1.4.1)
  - RDMA core: rdma-core-25.0 (distributed only) (no change)
  - Libfabric: libfabric-aws-1.9.0amzn1.1 (updated from libfabric-aws-1.8.1amzn1.3)
  - Open MPI: openmpi40-aws-4.0.2 (no change)
- Add SHA256 checksum verification to verify integrity of NICE DCV packages
- Upgrade Slurm to version 19.05.5
- Install Python 2.7.17 on CentOS 6 and set it as default through pyenv
- Install Ganglia from repository on Amazon Linux, Amazon Linux 2, CentOS 6 and CentOS 7
- Disable StrictHostKeyChecking for SSH client when target host is inside cluster VPC for all OSs except CentOS 6
- Pin Intel Python 2 and Intel Python 3 to version 2019.4  
- Automatically disable ptrace protection on Ubuntu 18.04 and Ubuntu 16.04 compute nodes when EFA is enabled
- Packer version >= 1.4.0 is required for AMI creation

**BUG FIXES**
- Fix issue with slurmd daemon not being restarted correctly when a compute node is rebooted
- Fix errors causing Torque not able to locate jobs, setting server_name to fqdn on master node
- Fix Torque issue that was limiting the max number of running jobs to the max size of the cluster
- Slurm: configured StateSaveLocation and SlurmdSpoolDir directories to be writable only to slurm user

2.5.1
-----

**CHANGES**
- Upgrade NVIDIA driver to Tesla version 440.33.01.
- Upgrade CUDA library to version 10.2.
- Upgrade EFA installer to version 1.7.1:
  - Kernel module: efa-1.4.1
  - RDMA core: rdma-core-25.0
  - Libfabric: libfabric-aws-1.8.1amzn1.3
  - Open MPI: openmpi40-aws-4.0.2

**BUG FIXES**
- Fix installation of NVIDIA drivers on Ubuntu 18.
- Fix installation of CUDA toolkit on Centos 6.
- Fix installation of Munge on Amazon Linux, Centos 6, Centos 7 and Ubuntu 16.
- Export shared directories to all CIDR blocks in a VPC rather than just the first one.

2.5.0
-----

**ENHANCEMENTS**
- Install NICE DCV on Centos 7 (this includes Gnome and Xorg packages).
- Install Intel Parallel Studio 2019.5 Runtime in Centos 7 AMI and share /opt/intel over NFS.
- Add support for Ubuntu 18.

**CHANGES**
- Remove support for Ubuntu 14.
- Upgrade Intel MPI to version U5.
- Upgrade EFA Installer to version 1.6.2, this also upgrades Open MPI to 4.0.2.
- Upgrade NVIDIA driver to Tesla version 418.87.
- Upgrade CUDA library to version 10.1.
- Upgrade Slurm to version 19.05.3-2.
- Slurm: changed following parameters in global configuration:
  - `SelectType=cons_tres`, `SelectTypeParameter=CR_CPU_Memory`, `GresTypes=gpu`: needed to enable support for GPU
    scheduling.
  - `EnforcePartLimits=ALL`: jobs which exceed a partition's size and/or time limits will be rejected at submission
    time.
  - Removed `FastSchedule` since deprecated.
  - `SlurmdTimeout=180`, `UnkillableStepTimeout=180`: to allow scheduler to recover especially when under heavy load.
- Echo compute instance type and memory information in COMPUTE_READY message
- Changes to sshd config:
  - Disable X11Forwarding by default
  - Limit SSH Ciphers to 
    `aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com`
  - Limit SSH MACs to `hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256`
- Increase default root volume to 25GB.
- Enable `flock user_xattr noatime` Lustre options by default everywhere and
  `x-systemd.automount x-systemd.requires=lnet.service` for systemd based systems.
- Install EFA in China AMIs. 

**BUG FIXES**
- Fix Ganglia not starting on Ubuntu 16
- Fix bug that was preventing nodes to mount partitioned EBS volumes.

2.4.1
-----

**ENHANCEMENTS**
- Install IntelMPI on Alinux, Centos 7 and Ubuntu 1604
- Upgrade EFA to version 1.4.1
- Run all node daemons and cookbook recipes in isolated Python virtualenvs. This allows our code to always run with the
  required Python dependencies and solves all conflicts and runtime failures that were being caused by user packages
  installed in the system Python

**CHANGES**
- Torque: upgrade to version 6.1.2
- Run all node daemons with Python 3.6
- Torque: changed following parameters in global configuration:
  - `server node_check_rate = 120` - Specifies the minimum duration (in seconds)
    that a node can fail to send a status update before being marked down by the
    pbs_server daemon. Previously was 600. This reduces scaling reaction times in
    case of instance failure or unexpected termination (especially with spot)
  - `server node_ping_rate = 60` - Specifies the maximum interval (in seconds)
    between successive "pings" sent from the pbs_server daemon to the pbs_mom
    daemon to determine node/daemon health. Previously was 300. Setting it to half
    the node_check_rate.
  - `server timeout_for_job_delete = 30` - The specific timeout used when deleting
    jobs because the node they are executing on is being deleted. Previously was
    120. This prevents job deletion to hang for more than 30 seconds when the node
    they are running on is being deleted.
  - `server timeout_for_job_requeue = 30` - The specific timeout used when requeuing
    jobs because the node they are executing on is being deleted. Previously was
    120. This prevents node deletion to hang for more than 30 seconds when a job
    cannot be rescheduled.

**BUG FIXES**
- Restore correct value for `filehandle_limit` that was getting reset when setting `memory_limit` for EFA
- Torque: fix configuration of server operators that was preventing compute nodes from disabling themselves
  before termination


2.4.0
-----

**ENHANCEMENTS**
- Add support for EFA on Centos 7, Amazon Linux and Ubuntu 1604
- Add support for Ubuntu in China region `cn-northwest-1`

**CHANGES**
- SGE: changed following parameters in global configuration
  - `max_unheard 00:03:00`: allows a faster reaction in case of faulty nodes
  - `reschedule_unknown 00:00:30`: enables rescheduling of jobs running on failing nodes
  - `qmaster_params ENABLE_FORCED_QDEL_IF_UNKNOWN`: forces job deletion on unresponsive nodes
  - `qmaster_params ENABLE_RESCHEDULE_KILL`: forces rescheduling or killing of jobs running on failing nodes
- Slurm: decrease SlurmdTimeout to 120 seconds to speed up replacement of faulty nodes
- Always use full master FQDN when mounting NFS on compute nodes. This solves some issues occurring with some networking
  setups and custom DNS configurations
- Set soft and hard ulimit on open files to 10000 for all supported OSs
- Pin python `supervisor` version to 3.4.0
- Remove unused `compute_instance_type` from jobwatcher.cfg
- Removed unused `max_queue_size` from sqswatcher.cfg
- Remove double quoting of the post_install args

**BUG FIXES**
- Fix issue that was preventing Torque from being used on Centos 7
- Start node daemons at the end of instance initialization. The time spent for post-install script and node
  initialization is not counted as part of node idletime anymore.
- Fix issue which was causing an additional and invalid EBS mount point to be added in case of multiple EBS
- Install Slurm libpmpi/libpmpi2 that is distributed in a separate package since Slurm 17


2.3.1
-----

**ENHANCEMENTS**
- FSx Lustre - add support in Amazon Linux

**CHANGES**
- Slurm - upgrade to version 18.08.6.2
- Slurm - declare nodes in separate config file and use FUTURE for dummy nodes
- Slurm - set `ReturnToService=1` in scheduler config in order to recover instances that were initially marked as down
  due to a transient issue.
- NVIDIA - update drivers to version 418.56
- CUDA - update toolkit to version 10.0
- Increase default EBS volume size from 15GB to 17GB
- Add `LocalHostname` to `COMPUTE_READY` events
- Pin `future`, `retrying` and `six` packages in Ubuntu 14.04
- Add `stackname` and `max_queue_size` to sqswatcher configuration


2.2.1
-----

**ENHANCEMENTS**
- `FSx Lustre`: add support for FSx Lustre in Centos7. In case of custom AMI, FSx Lustre is
  only supported with Centos 7.5 and Centos 7.6.

**CHANGES**
- `SGE`: allow users to force job deletion
- `Centos7`: use official AMI as the base image when building ParallelCluster AMI

**BUG FIXES**
- `Torque`: wait for scheduler initialization before completing compute node setup
- `EBS`: fix block device conversion to correctly attach ebs nvme volumes
- `Packer`: retrieve `aws-cfn-bootstrap-latest` package from `cn-north-1` in all China regions.
- `RAID`: automatically prepend `/` to `raid_shared_dir` when not specified in cluster config
- `EBS`: remove extra leading `/` when mounting EBS volumes

**TOOLING**
- Add a script to simplify cookbook package upload when using `custom_chef_cookbook` option


2.1.1
-----

- China Regions, cn-north-1 and cn-northwest-1 support

2.1.0
-----

- EFS support
- RAID support

2.0.2
-----

- Fix issue with jq on ubuntu1404 and centos6. Now using version 1.4
- Fix dependency issue with AWS CLI package on ubuntu1404

2.0.0
-----

- Rename CfnCluster to AWS ParallelCluster
- Support multiple EBS Volumes
- Add AWS Batch as a supported scheduler
- Support Custom AMI's


1.6.0
-----

- Add `scaledown_idletime` to nodewatcher config
- Add cookbook recipes for jobwatcher
- Remove publish_pending scripts


1.5.4
-----

- Set SGE Accounting summary to be true, this reports a single accounting record
for a mpi job
- Add option to disable ganglia `extra_json = { "cfncluster" : { "ganglia_enabled" : "no" } }`


1.5.2
-----

- Fix bug that prevented c5d/m5d instances from working
- Set CPU as a consumable resource in slurm config

1.5.1
-----

Major new features/updates:

  - Added parameter to specify custom cfncluster-node package

Bug fixes/minor improvements:

  - Fixed poise-python dependecy issue
  - Poll on EBS Volume attachment status
  - Added more info on failure of pre and post install files
  - Fixed SLURM cron job to publish pending metric

1.4.1
-----

Major new features/updates:

  - Updated to latest cfncluster-node 1.4.3

1.4.0
-----

Major new features/updates:

  - Updated to Amazon Linux 2017.09.1
  - Applied patches to Ubuntu 16.04
  - Applied patches to Ubuntu 14.04
  - Updated to Centos 7.4
  - Upgraded Centos 6 AMI
  - Updated to Nvidia driver 384
  - Updated to CUDA 9
  - Updated to latest cfncluster-node 1.4.2

Bug fixes/minor improvements:

  - Added support for NVMe-based instance store
  - Fixed ganglia plotting issue on ubuntu
  - Fixed slow SLURM scaling times on systemd platforms.

1.3.2
-----
  - Relicensed to Apache License 2.0
  - Updated to Amazon Linux 2017.03
  - Pulled in latest cookbook dependencies
  - Removed Openlava support

1.2.0
-----
- Dougal Ballantyne <dougalb at amazon dot com>
  - Updated to Chef 12.8.1
  - Updated Openlava to 3.1.3
  - Updated SGE to 8.1.9
  - Updated cfncluster-node to 1.1.0
  - Added slots to compute-ready script
  - Updated cookbook dependencies

1.1.0
-----
- Dougal Ballantyne <dougalb at amazon dot com> - Updated to Amazon Linux 2015.09.2 for base AMI

1.0.1
-----
- Dougal Ballantyne <dougalb at amazon dot com>
  - Fix Ganglia rebuild on 2nd run
  - Update to cfncluster-node==1.0.1

1.0.0
-----
- Dougal Ballantyne <dougalb at amazon dot com> - 1.0.0 release of cookbook matching 1.0.0 release of cfncluster.

0.1.0
-----
- Dougal Ballantyne <dougalb at amazon dot com> - Initial release of cfncluster-cookbooks
