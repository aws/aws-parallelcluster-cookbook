aws-parallelcluster-cookbook CHANGELOG
======================================

This file is used to list changes made in each version of the AWS ParallelCluster cookbook.

x.x.x
------

**ENHANCEMENTS**
- Add support for multiple Elastic File Systems.
- Add support for multiple FSx File System.
- Add support for attaching existing FSx for Ontap and FSx for OpenZFS File Systems.
- Install NVIDIA GDRCopy 2.3 to enable low-latency GPU memory copy on supported instance types.
- Slurm: Set `AuthInfo=cred_expire=70` to reduce the time requeued jobs must wait before starting again when nodes are not available.
- Make `DirectoryService/AdditionalSssdConfigs` be merged into final SSSD configuration rather than be appended.
- During cluster update set Slurm nodes state accordingly to strategy set through QueueUpdateStrategy parameter.
- Add new configuration parameter `Scheduling/SlurmSettings/EnableMemoryBasedScheduling` to configure memory-based
  scheduling in Slurm.
  - Move `SelectTypeParameters` and `ConstrainRAMSpace` to the `parallelcluster_slurm*.conf` include files.
  - Add new configuration parameter to override default value of schedulable memory on compute nodes.
- Add support for rebooting compute nodes via Slurm.

**CHANGES**
- Slurm: Restart `clustermgtd` and `slurmctld` daemons at cluster update time only when `Scheduling` parameters are updated in the cluster configuration.
- Update slurmctld and slurmd systemd service files.
- Upgrade NICE DCV to version 2022.0-12760.
- Upgrade NVIDIA driver to version 470.129.06.
- Upgrade NVIDIA Fabric Manager to version 470.129.06.
- Upgrade EFA installer to version 1.16.0.
  - EFA driver: ``efa-1.16.0-1``
  - EFA configuration: ``efa-config-1.10-1``
  - EFA profile: ``efa-profile-1.5-1``
  - Libfabric: ``libfabric-aws-1.15.1.amzn1.0-1``
  - RDMA core: ``rdma-core-39.0-2``
  - Open MPI: ``openmpi40-aws-4.1.2-2``
- Restrict IPv6 access to IMDS to root and cluster admin users only.

3.1.4
------

**CHANGES**
- Upgrade Slurm to version 21.08.8.

**ENHANCEMENTS**
- Add support for enabling JWT authentication Slurm.

3.1.3
------

**ENHANCEMENTS**
- Execute SSH key creation alongside with the creation of HOME directory, i.e.
  during SSH login, when switching to another user and when executing a command as another user.
- Add support for both FQDN and LDAP Distinguished Names in the configuration parameter `DirectoryService/DomainName`. The new validator now checks both the syntaxes.
- New `update_directory_service_password.sh` script deployed on the head node supports the manual update of the Active Directory password in the SSSD configuration.
  The password is retrieved by the AWS Secrets Manager as from the cluster configuration.
- Make `DirectoryService/AdditionalSssdConfigs` be merged into final SSSD configuration rather than be appended.

**CHANGES**
- Disable deeper C-States in x86_64 official AMIs and AMIs created through `build-image` command, to guarantee high performance and low latency.
- Change Amazon Linux 2 base images to use AMIs with Kernel 5.10.

**BUG FIXES**
- Fix the configuration parameter `DirectoryService/DomainAddr` conversion to `ldap_uri` SSSD property when it contains multiples domain addresses.
- Fix DCV not loading user profile at session start. The user's PATH was not correctly set at DCV session connection.  

3.1.2
------

**CHANGES**
- Upgrade Slurm to version 21.08.6.

**BUG FIXES**
- Fix the update of `/etc/hosts` file on computes nodes when a cluster is deployed in subnets without internet access.
- Fix compute nodes bootstrap by waiting for ephemeral drives initialization before joining the cluster.

3.1.1
------

**ENHANCEMENTS**
- Add support for multiple users cluster environments by integrating with Active Directory (AD) domains managed via AWS Directory Service.
- Install NVIDIA drivers and CUDA library for ARM.

**CHANGES**
- Upgrade Slurm to version 21.08.5.
- Upgrade NICE DCV to version 2021.3-11591.
- Upgrade NVIDIA driver to version 470.103.01.
- Upgrade CUDA library to version 11.4.4.
- Upgrade NVIDIA Fabric manager to version 470.103.01.
- Upgrade Intel MPI Library to 2021.4.0.441.
- Upgrade PMIx to version 3.2.3.
- Move the configure/install recipes to separate cookbooks that are called from the main one. Existing entrypoints are maintained and backwards compatible.
- Download dependencies of Intel HPC platform during AMI build time to avoid contacting internet during cluster creation time.
- Do not strip `-` from compute resource name when configuring Slurm nodes.
- Add cluster parameter `directory_service.disabled_on_compute_nodes` to disable AD integration on compute nodes.

**BUG FIXES**
- Do not configure GPUs in Slurm when NVIDIA driver is not installed.
- Fix the way `ExtraChefAttributes` are merged into the final configuration.
- Fix sporadic failure of build-image due to missing package

3.0.3
------

**CHANGES**
- Disable log4j-cve-2021-44228-hotpatch service on Amazon Linux to avoid incurring in potential performance degradation.

3.0.2
------

**CHANGES**
- Upgrade EFA installer to version 1.14.1. Thereafter, EFA enables GDR support by default on supported instance type(s).
  ParallelCluster does not reinstall EFA during node start. Previously, EFA was reinstalled if `GdrSupport` had been
  turned on in the configuration file.
  - EFA configuration: ``efa-config-1.9-1``
  - EFA profile: ``efa-profile-1.5-1``
  - EFA kernel module: ``efa-1.14.2``
  - RDMA core: ``rdma-core-37.0``
  - Libfabric: ``libfabric-1.13.2``
  - Open MPI: ``openmpi40-aws-4.1.1-2``

**BUG FIXES**
- Fix issue that is preventing cluster names to start with `parallelcluster-` prefix.

3.0.1
------

**CHANGES**
- Change supervisord service script from SysVinit to Systemd.
- Drop support for SysVinit. Only Systemd is supported.

**BUG FIXES**
- Fix supervisord service not enabled on Ubuntu.
- Update ca-certificates package during AMI build time and prevent Chef from using outdated/distrusted CA certificates.

3.0.0
------

**ENHANCEMENTS**
- Support restart/reboot for instance type with instance store (ephemeral drives).
- Compile Slurm with jobcomp/elasticsearch support.

**CHANGES**
- Update pre / post install scripts to drop the first argument which was the script being run
- Drop support for SGE and Torque schedulers.
- Drop support for CentOS8.
- Remove nodewatcher, sqswatcher, jobwatcher related code.
- Remove Ganglia support.
- Install ParallelCluster AWS Batch CLI at AMI build time.
- Run daemons as cluster admin user (not root).
- Add explicit assignment of names, uids, gids for slurm, munge and dcvextauth users.
- Remove packer.
- Restrict access to IMDS to root and cluster admin users, only.
- Make PATH include required directories for every user and recipes context.
- Fail cluster creation when IMDS lockdown is not working correctly.
- Make sudoers secure_path include the same directories in every platform.
- Remove option for instance store software encryption (encrypted_ephemeral).
- Add support for iptables restore on instance reboot.
- Allow IMDS access for dcv user when dcv is enabled.
- Restore ``noatime`` option, which has positive impact on the performances of NFS filesystem
- Upgrade NICE DCV to version 2021.1-10851.
- Upgrade Slurm to version 20.11.8
- Upgrade Cinc Client to version 17.2.29.
- Upgrade NVIDIA driver to version 470.57.02.
- Upgrade CUDA library to version 11.4.0.
- Avoid installing MPICH and FFTW packages.
- Upgrade EFA installer to version 1.13.0
  - Update rdma-core to v35.0.
  - Update libfabric to v1.13.0amzn1.0.

**BUG FIXES**
- Fix cluster update when using proxy setup

2.11.3
-----

**CHANGES**
- Upgrade EFA installer to version 1.14.1. Thereafter, EFA enables GDR support by default on supported instance type(s).
  ParallelCluster does not reinstall EFA during node start. Previously, EFA was reinstalled if `enable_efa_gdr` had been
  turned on in the configuration file.
  - EFA configuration: ``efa-config-1.9-1``
  - EFA profile: ``efa-profile-1.5-1``
  - EFA kernel module: ``efa-1.14.2``
  - RDMA core: ``rdma-core-37.0``
  - Libfabric: ``libfabric-1.13.2``
  - Open MPI: ``openmpi40-aws-4.1.1-2``

**BUG FIXES**
- Fix failure when building AMI, due to SGE sources not available at arc.liv.ac.uk
- Fix cluster update when using proxy setup.
- Update ca-certificates package during AMI build time and prevent Chef from using outdated/distrusted CA certificates.

2.11.2
-----

**CHANGES**
When using a custom AMI with a preinstalled EFA package, no actions are taken at node bootstrap time in case GPUDirect RDMA is enabled. The original EFA package deployment is preserved as during the Image build process.

**BUG FIXES**
- Lock version of `nvidia-fabricmanager` package to prevent updates and misalignments with NVIDIA drivers

2.11.1
-----

**ENHANCEMENTS**
- Retry failed installations of aws-parallelcluster package on head node of clusters using AWS Batch as the scheduler.

**CHANGES**
- Restore ``noatime`` option, which has positive impact on the performances of NFS filesystem.
- Upgrade EFA installer to version 1.12.3
  - EFA configuration: ``efa-config-1.9`` (from ``efa-config-1.8-1``)
  - EFA kernel module: ``efa-1.13.0`` (from ``efa-1.12.3``)

**BUG FIXES**
- Pin to version 1.247347 of the CloudWatch agent due to performance impact of latest CW agent version 1.247348.
- Avoid failures when building SGE using instance type with vCPU >=32.

2.11.0
-----

**ENHANCEMENTS**
- Add support for Ubuntu 20.04.
- Add support for using FSx Lustre in subnet with no internet access.
- Add support for building Centos 7 AMIs on ARM.
- Make sure slurmd service is only enabled after post-install process, which will prevent user from unintentionally making compute node available during post-install process.
- Change to ssh_target_checker.sh syntax that makes the script compatible with pdsh.
- Add possibility to use a post installation script when building Centos 8 AMI.
- Install SSM agent on CentOS 7 and 8.
- Transition from IMDSv1 to IMDSv2.
- Add support for `security_group_id` in packer custom builders. Customers can export `AWS_SECURITY_GROUP_ID` environment variable to specify security group for custom builders when building custom AMIs.
- Configure the following default gc_thresh values for performance at scale.
  - net.ipv4.neigh.default.gc_thresh1 = 0
  - net.ipv4.neigh.default.gc_thresh2 = 15360
  - net.ipv4.neigh.default.gc_thresh3 = 16384

**CHANGES**
- Ubuntu 16.04 is no longer supported.
- Amazon Linux is no longer supported.
- Upgrade EFA installer to version 1.12.2
  - EFA configuration: ``efa-config-1.8-1`` (from ``efa-config-1.7``)
  - EFA profile: ``efa-profile-1.5-1`` (from ``efa-profile-1.4``)
  - EFA kernel module: ``efa-1.12.3`` (from ``efa-1.10.2``)
  - RDMA core: ``rdma-core-32.1amzn`` (from ``rdma-core-31.2amzn``)
  - Libfabric: ``libfabric-1.11.2amzon1.1-1`` (from ``libfabric-1.11.1amzn1.0``)
  - Open MPI: ``openmpi40-aws-4.1.1-2`` (from ``openmpi40-aws-4.1.0``)
- Increase timeout when attaching EBS volumes from 3 to 5 minutes.
- Retry `berkshelf` installation up to 3 times.
- Root volume size increased from 25GB to 35GB on all AMIs. Minimum root volume size is now 35GB.
- Upgrade Slurm to version 20.11.7.
  - Update slurmctld and slurmd systemd unit files according to latest provided by slurm
  - Add new SlurmctldParameters, power_save_min_interval=30, so power actions will be processed every 30 seconds
  - Specify instance GPU model as GRES GPU Type in gres.conf, instead of previous hardcoded value ``Type=tesla`` for all GPU
- Upgrade Arm Performance Libraries (APL) to version 21.0.0
- Upgrade NICE DCV to version 2021.1-10557.
- Upgrade NVIDIA driver to version 460.73.01.
- Upgrade CUDA library to version 11.3.0.
- Upgrade NVIDIA Fabric manager to `nvidia-fabricmanager-460`.
- Install ParallelCluster AWSBatch CLI in dedicated python3 virtual env.
- Upgrade Python version used in ParallelCluster virtualenvs from version 3.6.13 to version 3.7.10.
- Upgrade Cinc Client to version 16.13.16.
- Upgrade third-party cookbook dependencies:
  - apt-7.4.0 (from apt-7.3.0)
  - iptables-8.0.0 (from iptables-7.1.0)
  - line-4.0.1 (from line-2.9.0)
  - openssh-2.9.1 (from openssh-2.8.1)
  - pyenv-3.4.2 (from pyenv-3.1.1)
  - selinux-3.1.1 (from selinux-2.1.1)
  - ulimit-1.1.1 (from ulimit-1.0.0)
  - yum-6.1.1 (from yum-5.1.0)
  - yum-epel-4.1.2 (from yum-epel-3.3.0)
- Drop ``lightdm`` package install from Ubuntu 18.04 DCV installation process.
- Update default NFS options used by Compute nodes to mount shared filesystem from head node.
  - Drop ``intr`` option, which is deprecated since kernel 2.6.25
  - Drop ``noatime`` option, which is not relevant for NFS mount

2.10.4
-----

**CHANGES**
- Upgrade Slurm to version 20.02.7

2.10.3
-----

**CHANGES**
- Upgrade EFA installer to version 1.11.2
  - EFA configuration: ``efa-config-1.7`` (no change)
  - EFA profile: ``efa-profile-1.4`` (from ``efa-profile-1.3``)
  - EFA kernel module: ``efa-1.10.2`` (no change)
  - RDMA core: ``rdma-core-31.2amzn`` (no change)
  - Libfabric: ``libfabric-1.11.1amzn1.0`` (no change)
  - Open MPI: ``openmpi40-aws-4.1.0`` (no change)

2.10.2
-----

**ENHANCEMENTS**
- Improve configuration procedure for the Munge service.

**CHANGES**
- Update Python version used in ParallelCluster virtualenvs from version 3.6.9 to version 3.6.13.

**BUG FIXES**
- Use non interactive `apt update` command when building custom Ubuntu AMIs.
- Fix `encrypted_ephemeral = true` when using Alinux2 or CentOS8

2.10.1
------

**ENHANCEMENTS**
- Install Arm Performance Libraries (APL) 20.2.1 on ARM AMIs (CentOS8, Alinux2, Ubuntu1804).
- Install EFA kernel module on ARM instances with `alinux2` and `ubuntu1804`.
- Configure NFS threads to be max(8, num_cores) for performance. This enhancement will not take effect on Ubuntu 16.04.

**CHANGES**
- Upgrade EFA installer to version 1.11.1.
  - EFA configuration: ``efa-config-1.7`` (from efa-config-1.5)
  - EFA profile: ``efa-profile-1.3`` (from efa-profile-1.1)
  - EFA kernel module: ``efa-1.10.2`` (no change)
  - RDMA core: ``rdma-core-31.2amzn`` (from rdma-core-31.amzn0)
  - Libfabric: ``libfabric-1.11.1amzn1.0`` (from libfabric-1.11.1amzn1.1)
  - Open MPI: ``openmpi40-aws-4.1.0`` (from openmpi40-aws-4.0.5)
- Upgrade Intel MPI to version U8.
- Upgrade NICE DCV to version 2020.2-9662.
- Set default systemd runlevel to multi-user.target on all OSes during ParallelCluster official ami creation.
  The runlevel is set to graphical.target on head node only when DCV is enabled. This prevents the execution of
  graphical services, such as x/gdm, when they are not required.
- Download Intel MPI and HPC packages from S3 rather than Intel yum repos.

**BUG FIXES**
- Fix installation of Intel PSXE package on CentOS 7 by using yum4.
- Fix routing issues with multiple Network Interfaces on Ubuntu 18.04.
- Fix compilation of SGE by downloading sources from Debian repository and not from the EOL Ubuntu 19.10.

2.10.0
------

**ENHANCEMENTS**

- Add support for CentOS 8.
- Add support for instance types with multiple network cards (e.g. `p4d.24xlarge`).
- Enable FSx Lustre in China regions.
- Add validation step for AMI creation process to fail when using a base AMI created by a different version of
  ParallelCluster.
- Add validation step for AMI creation process to fail if the selected OS and the base AMI OS are not consistent.
- Add possibility to use a post installation script when building an AMI.
- Install NVIDIA Fabric manager to enable NVIDIA NVSwitch on supported platforms.

**CHANGES**
- Upgrade EFA installer to version 1.10.1
  - EFA configuration: ``efa-config-1.5`` (from efa-config-1.4)
  - EFA profile: ``efa-profile-1.1`` (from efa-profile-1.0.0)
  - EFA kernel module: ``efa-1.10.2`` (from efa-1.6.0)
  - RDMA core: ``rdma-core-31.amzn0`` (from rdma-core-28.amzn0)
  - Libfabric: ``libfabric-1.11.1amzn1.1`` (from libfabric-1.10.1amzn1.1)
  - Open MPI: ``openmpi40-aws-4.0.5`` (from openmpi40-aws-4.0.3)
  - Unifies installer runtime options across x86 and aarch64
  - Introduces ``-g/--enable-gdr`` switch to install packages with GPUDirect RDMA support
  - Updates to OMPI collectives decision file packaging, migrated from efa-config to efa-profile
  - Introduces CentOS 8 support
- CentOS 6 is no longer supported.
- Upgrade NVIDIA driver to version 450.80.02.
- Upgrade Intel Parallel Studio XE Runtime to version 2020.2.
- Upgrade Munge to version 0.5.14.
- Retrieve FSx Lustre DNS name dynamically.
- Slurm: change `SlurmctldPort` to 6820-6829 to not overlap with default `slurmdbd` port (6819).
- Slurm: add `compute_resource` name and `efa` as node features.
- Improve Slurm and Munge installation process by cleaning up existing installations from OS repositories.
- Install Python 3 version of ``aws-cfn-bootstrap`` scripts.
- Do not force compute fleet into `STOPPED` state when performing a cluster update. This allows to update the queue
  size without forcing a termination of the existing instances.

**BUG FIXES**
- Fix ephemeral drives setup to avoid failures when partition changes require a reboot.
- Fix Chrony service management.
- Retrieve the right number of compute instance slots when instance type is updated.
- Fix compute fleet status initialization to be configured before daemons are started by `supervisord`.

2.9.1
-----

**CHANGES**

- There were no notable changes for this version.

2.9.0
-----

**ENHANCEMENTS**

- Add support for multiple queues and multiple instance types feature with the Slurm scheduler.
- Extend NICE DCV support to ARM instances.
- Extend support to disable hyperthreading on instances (like \*.metal) that don't support CpuOptions in
  LaunchTemplate.
- Enable support for NFS 4 for the filesystems shared from the head node.
- Add script wrapper to support Torque-like commands with the Slurm scheduler.

**CHANGES**

- A Route53 private hosted zone is now created together with the cluster and used in DNS resolution inside cluster nodes
    when using Slurm scheduler.
- Upgrade EFA installer to version 1.9.5:
  - EFA configuration: ``efa-config-1.4`` (from efa-config-1.3)
  - EFA profile: ``efa-profile-1.0.0``
  - EFA kernel module: ``efa-1.6.0`` (no change)
  - RDMA core: ``rdma-core-28.amzn0`` (no change)
  - Libfabric: ``libfabric-1.10.1amzn1.1`` (no change)
  - Open MPI: ``openmpi40-aws-4.0.3`` (no change)
- Upgrade Slurm to version 20.02.4.
- Apply the following changes to Slurm configuration:
  - Assign a range of 10 ports to Slurmctld in order to better perform with large cluster settings
  - Configure cloud scheduling logic
  - Set `ReconfigFlags=KeepPartState`
  - Set `MessageTimeout=60`
  - Set `TaskPlugin=task/affinity,task/cgroup` together with `TaskAffinity=no` and `ConstrainCores=yes` in cgroup.conf
- Upgrade NICE DCV to version 2020.1-9012.
- Use private ip instead of master node hostname when mounting shared NFS drives.
- Add new log streams to CloudWatch: chef-client, clustermgtd, computemgtd, slurm_resume, slurm_suspend.
- Remove dependency on cfn-init in compute nodes bootstrap.
- Add support for queue names in pre/post install scripts.

**BUG FIXES**

- Solve dpkg lock issue with Ubuntu that prevented custom AMI creation in some cases.

2.8.1
-----

**CHANGES**

- Disable screen lock for DCV desktop sessions to prevent users from being locked out.

2.8.0
-----

**ENHANCEMENTS**

- Enable support for ARM instances on Ubuntu 18.04 and Amazon Linux 2.
- Install  PMIx v3.1.5 and provide slurm support for it on all supported operating systems except for
  CentOS 6.
- Install glibc-static, which is required to support certain options for the Intel MPI compiler.

**CHANGES**

- Disable libvirtd service on Centos 7. Virtual bridge interfaces are incorrectly detected by Open MPI and
  cause MPI applications to hang, see https://www.open-mpi.org/faq/?category=tcp#tcp-selection for details
- Use CINC instead of Chef for provisioning instances. See https://cinc.sh/about/ for details.
- Retry when mounting an NFS mount fails.
- Install the `pyenv` virtual environments used by ParallelCluster cookbook and node daemon code under
  /opt/parallelcluster instead of under /usr/local.
- Avoid downloading the source for `env2` at installation time.
- Drop dependency on the gems ridley and ffi-libarchive.
- Vendor cookbooks as part of instance provisioning, rather than doing so before copying the cookbook into an
  instance. Users no longer need to have `berks` installed locally.
- Drop the dependencies on the poise-python, tar and hostname third-party cookbooks.
- Use the new official CentOS 7 AMI as the base images for ParallelCluster AMI.
- Upgrade NVIDIA driver to Tesla version 440.95.01 on CentOS 6 and version 450.51.05 on all other distros.
- Upgrade CUDA library to version 11.0 on all distros besides CentOS 6.
- Install third-party cookbook dependencies via local source, rather than using the Chef supermarket.
- Use https wherever possible in download URLs.
- Upgrade EFA installer to version 1.9.4:
  - Kernel module: ``efa-1.6.0`` (from efa-1.5.1)
  - RDMA core: ``rdma-core-28.amzn0`` (from rdma-core-25.0)
  - Libfabric: ``libfabric-1.10.1amzn1.1`` (updated from libfabric-aws-1.9.0amzn1.1)
  - Open MPI: openmpi40-aws-4.0.3 (no change)

**BUG FIXES**
- Fix issue that was preventing concurrent use of custom node and pcluster CLI packages.
- Use the correct domain name when contacting AWS services from the China partition.
- Avoid pinning to a specific release of the Intel HPC platform.

2.7.0
-----

**CHANGES**

- Upgrade NICE DCV to version 2020.0-8428.
- Upgrade Intel MPI to version U7.
- Upgrade NVIDIA driver to version 440.64.00.
- Upgrade EFA installer to version 1.8.4:
  - Kernel module: ``efa-1.5.1`` (no change)
  - RDMA core: ``rdma-core-25.0`` (no change)
  - Libfabric: ``libfabric-aws-1.9.0amzn1.1`` (no change)
  - Open MPI: openmpi40-aws-4.0.3 (updated from openmpi40-aws-4.0.2)
- Upgrade CentOS 7 AMI to version 7.8

**BUG FIXES**

- Fix recipes installation at runtime by adding the bootstrapped file at the end of the last chef run.
- Fix installation of Lustre client on Centos 7
- FSx Lustre: Exit with error when failing to retrieve FSx mountpoint.

2.6.2
-----

**ENHANCEMENTS**

**CHANGES**
- Upgrade Intel MPI to version 2019 U7.

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
