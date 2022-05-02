# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: tests
#
# Copyright:: 2013-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'aws-parallelcluster-test::test_envars'
include_recipe 'aws-parallelcluster-test::test_users'
include_recipe 'aws-parallelcluster-test::test_processes'
include_recipe 'aws-parallelcluster-test::test_imds'
include_recipe 'aws-parallelcluster-test::test_sudoers'
include_recipe 'aws-parallelcluster-test::test_openssh'
include_recipe 'aws-parallelcluster-test::test_nvidia'
include_recipe 'aws-parallelcluster-test::test_dcv'

###################
# AWS Cli
###################
bash 'check awscli regions' do
  cwd Chef::Config[:file_cache_path]
  code <<-AWSREGIONS
    set -e
    export PATH="/usr/local/bin:/usr/bin/:$PATH"
    regions=($(#{node['cluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region #{node['cluster']['region']} --query "Regions[].{Name:RegionName}" --output text))
    for region in "${regions[@]}"
    do
      #{node['cluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region "${region}"
    done
  AWSREGIONS
end

###################
# SSH client conf
###################
execute 'grep ssh_config' do
  command 'grep -Pz "Match exec \"ssh_target_checker.sh %h\"\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null" /etc/ssh/ssh_config'
end

# Test only on head node since on compute fleet an empty /home is mounted for the Kitchen tests run
if node['cluster']['node_type'] == 'HeadNode'
  execute 'ssh localhost as user' do
    command "ssh localhost hostname"
    environment('PATH' => '/usr/local/bin:/usr/bin:/bin:$PATH')
    user node['cluster']['cluster_user']
  end
end

###################
# Slurm
###################
if node['cluster']['scheduler'] == 'slurm'
  execute 'check munge service is enabled' do
    command "systemctl is-enabled munge"
  end
  case node['cluster']['node_type']
  when 'HeadNode'
    execute 'execute sinfo' do
      command "sinfo --help"
      environment('PATH' => "#{node['cluster']['slurm']['install_dir']}/bin:/bin:/usr/bin:$PATH")
      user node['cluster']['cluster_user']
    end

    execute 'execute scontrol' do
      command "scontrol --help"
      environment('PATH' => "#{node['cluster']['slurm']['install_dir']}/bin:/bin:/usr/bin:$PATH")
      user node['cluster']['cluster_user']
    end

    execute 'check-slurm-accounting-mysql-plugins' do
      command "ls #{node['cluster']['slurm']['install_dir']}/lib/slurm/ | grep accounting_storage_mysql"
    end

    execute 'check-slurm-jobcomp-mysql-plugins' do
      command "ls #{node['cluster']['slurm']['install_dir']}/lib/slurm/ | grep jobcomp_mysql"
    end

    execute 'check-slurm-pmix-plugins' do
      command "ls #{node['cluster']['slurm']['install_dir']}/lib/slurm/ | grep pmix"
    end
    execute 'ensure-pmix-shared-library-can-be-found' do
      command '/opt/pmix/bin/pmix_info'
    end
    execute 'check slurmctld service is enabled' do
      command "systemctl is-enabled slurmctld"
    end
  when 'ComputeFleet'
    execute 'ls slurm root' do
      command "ls #{node['cluster']['slurm']['install_dir']}"
      user node['cluster']['cluster_user']
    end
  else
    raise "node_type must be HeadNode or ComputeFleet"
  end
end
###################
# Scheduler Plugin
###################
if node['cluster']['scheduler'] == 'plugin'
  if node['cluster']['node_type'] == "HeadNode"
    execute 'check artifacts are in target_source_path' do
      command "ls #{node['cluster']['scheduler_plugin']['home']} | grep develop"
    end
    execute 'check handler-env.json in path' do
      command "ls #{node['cluster']['shared_dir']}/handler-env.json"
    end
    execute 'check get compute fleet script is executable by plugin user' do
      command "su #{node['cluster']['scheduler_plugin']['user']} -c 'if [[ ! -x '/usr/local/bin/get-compute-fleet-status.sh' ]]; then exit 1; fi;'"
    end
    execute 'check update compute fleet script is executable by plugin user' do
      command "su #{node['cluster']['scheduler_plugin']['user']} -c 'if [[ ! -x '/usr/local/bin/update-compute-fleet-status.sh' ]]; then exit 1; fi;'"
    end
  end
  execute "check scheduler plugin user doesn't have Sudo Privileges" do
    command "(su #{node['cluster']['scheduler_plugin']['user']} -c 'sudo -ln') 2>&1 | grep 'a password is required'"
  end
end

###################
# Amazon Time Sync
###################
get_chrony_status_command = "systemctl show -p SubState #{node['cluster']['chrony']['service']}"
# $ systemctl show -p SubState <service>
# SubState=Running

chrony_check_command = "#{get_chrony_status_command} | grep -i running"

ruby_block 'log_chrony_status' do
  block do
    get_chrony_service_log_command = "journalctl -u #{node['cluster']['chrony']['service']}"
    chrony_log = shell_out!(get_chrony_service_log_command).stdout
    Chef::Log.debug("chrony service log: #{chrony_log}")
    chrony_status = shell_out!(get_chrony_status_command).stdout
    Chef::Log.debug("chrony status is #{chrony_status}")
  end
end

execute 'check chrony running' do
  command chrony_check_command
end

execute 'check chrony service is enabled' do
  command "systemctl is-enabled #{node['cluster']['chrony']['service']}"
end

execute 'check chrony conf' do
  command "chronyc waitsync 30; chronyc tracking | grep -i reference | grep 169.254.169.123"
  user node['cluster']['cluster_user']
end

###################
# DCV
###################
if node['cluster']['node_type'] == "HeadNode" &&
   node['conditions']['dcv_supported'] &&
   (node['cluster']['dcv']['installed'] == 'yes' || node['cluster']['dcv']['installed'] == true)
  execute 'check dcv installed' do
    command 'dcv version'
    user node['cluster']['cluster_user']
  end
  execute 'check DCV external authenticator python version' do
    command %(#{node['cluster']['dcv']['authenticator']['virtualenv_path']}/bin/python -V | grep "Python #{node['cluster']['python-version']}")
  end
  execute 'check screensaver screen lock disabled' do
    command 'gsettings get org.gnome.desktop.screensaver lock-enabled | grep false'
  end
  execute 'check non-screensaver screen lock disabled' do
    command 'gsettings get org.gnome.desktop.lockdown disable-lock-screen | grep true'
  end
end

if node['conditions']['dcv_supported'] && node['cluster']['dcv_enabled'] == "head_node" && node['cluster']['node_type'] == "HeadNode"
  execute 'check dcvserver service is enabled' do
    command "systemctl is-enabled dcvserver"
  end
  execute 'check systemd default runlevel' do
    command "systemctl get-default | grep -i graphical.target"
  end
  if graphic_instance? && dcv_gpu_accel_supported?
    execute "Ensure local users can access X server (dcv-gl must be installed)" do
      command %?DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') xhost | grep "LOCAL:$"?
    end
  end
  if node['cluster']['os'] == "ubuntu1804" || node['cluster']['os'] == "alinux2"
    execute 'check gdm service is running' do
      command "systemctl show -p SubState gdm | grep -i running"
    end
  end
elsif node['conditions']['ami_bootstrapped']
  execute 'check systemd default runlevel' do
    command "systemctl get-default | grep -i multi-user.target"
  end
  if node['cluster']['os'] == "ubuntu1804" || node['cluster']['os'] == "alinux2"
    execute 'check gdm service is stopped' do
      command "systemctl show -p SubState gdm | grep -i dead"
    end
  end
end

###################
# EFA - Intel MPI
###################
if node['conditions']['intel_mpi_supported']
  if node['cluster']['os'] == 'ubuntu1804'
    case node['cluster']['node_type']
    when 'HeadNode'
      execute 'check ptrace protection enabled' do
        command "sysctl kernel.yama.ptrace_scope | grep 'kernel.yama.ptrace_scope = 1'"
        user node['cluster']['cluster_user']
      end
    when 'ComputeFleet'
      execute 'check ptrace protection disabled' do
        command "sysctl kernel.yama.ptrace_scope | grep 'kernel.yama.ptrace_scope = 0'"
        user node['cluster']['cluster_user']
      end
    end
  end

  # Test only on head node since on compute nodes we mount an empty /opt/intel drive in kitchen tests that
  # overrides intel binaries.
  if node['cluster']['node_type'] == 'HeadNode'
    bash 'check intel mpi version' do
      cwd Chef::Config[:file_cache_path]
      code <<-INTELMPI
        set -e
        # Initialize module
        # Unset MODULEPATH to force search path reinitialization when loading profile
        unset MODULEPATH
        # Must execute this in a bash script because source is a bash built-in function
        source /etc/profile.d/modules.sh
        module load intelmpi && mpirun --help | grep '#{node['cluster']['intelmpi']['kitchen_test_string']}'
      INTELMPI
      user node['cluster']['cluster_user']
    end
  end
end

###################
# EFA
###################
if node['conditions']['efa_supported']
  if node['cluster']['os'].end_with?("-custom")
    # only check EFA is installed because when found in the base AMI we skip installation
    bash 'check efa installed' do
      cwd Chef::Config[:file_cache_path]
      code <<-EFA
        set -ex
        modinfo efa
        cat /opt/amazon/efa_installed_packages
      EFA
    end
  else
    # check EFA is installed and the version is expected
    bash 'check correct version of efa installed' do
      cwd Chef::Config[:file_cache_path]
      code <<-EFA
        set -ex
        modinfo efa
        grep "EFA installer version: #{node['cluster']['efa']['installer_version']}" /opt/amazon/efa_installed_packages
      EFA
    end
    # GDR (GPUDirect RDMA)
    execute 'check efa gdr installed' do
      command "modinfo efa | grep 'gdr:\ *Y'"
      user node['cluster']['cluster_user']
    end
  end
end

###################
# jq
###################
unless node['cluster']['os'].end_with?("-custom")
  bash 'execute jq' do
    cwd Chef::Config[:file_cache_path]
    code <<-JQMERGE
      set -e
      # Set PATH as in the UserData script of the CloudFormation template
      export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin"
      echo '{"cluster": {"region": "eu-west-3"}, "run_list": "recipe[aws-parallelcluster::slurm_config]"}' > /tmp/dna.json
      echo '{ "cluster" : { "dcv_enabled" : "head_node" } }' > /tmp/extra.json
      jq --argfile f1 /tmp/dna.json --argfile f2 /tmp/extra.json -n '$f1 * $f2'
    JQMERGE
  end
end

###################
# Bridge Network Interface
###################
if platform?('centos')
  bash 'test bridge network interface presence' do
    code <<-TESTBRIDGE
      set -e
      # brctl show
      # bridge name bridge id STP enabled interfaces
      # virbr0 8000.525400e6e4f9 yes virbr0-nic
      [ $(brctl show | awk 'FNR == 2 {print $1}') ] && exit 1 || exit 0
    TESTBRIDGE
  end
end

###################
# NFS
###################

case node['cluster']['node_type']
when 'ComputeFleet'
  execute 'check for nfs client protocol' do
    command "nfsstat -m | grep vers=4"
    user node['cluster']['cluster_user']
  end
when 'HeadNode'
  execute 'check for nfs server protocol' do
    command "rpcinfo -p localhost | awk '{print $2$5}' | grep 4nfs"
    user node['cluster']['cluster_user']
  end
end

# Skip nfs thread test for ubuntu16 because nfs thread enhancement is omitted
require 'bigdecimal/util'
unless platform?('ubuntu') && node['platform_version'].to_d == 16.04.to_d
  ruby_block 'check_nfs_threads' do
    block do
      nfs_threads = shell_out!("cat /proc/net/rpc/nfsd | grep th | awk '{print$2}'").stdout.strip.to_i
      Chef::Log.debug("nfs threads configured on machine is #{nfs_threads}")
      expected_threads = [node['cpu']['cores'].to_i, 8].max
      raise "Expected number of nfs threads configured to be #{expected_threads} but is actually #{nfs_threads}" if nfs_threads != expected_threads
    end
    action :nothing
  end

  # Execute thread check at the end of chef run
  ruby_block 'delay thread check' do
    block do
      true
    end
    notifies :run, "ruby_block[check_nfs_threads]", :delayed
  end
end

###################
# ulimit
###################
unless node['cluster']['os'].end_with?("-custom")
  bash 'test soft ulimit nofile' do
    code "if (($(ulimit -Sn) < 8192)); then exit 1; fi"
    user node['cluster']['cluster_user']
  end
end

###################
# instance store
###################
bash 'test instance store' do
  cwd Chef::Config[:file_cache_path]
  code <<-EPHEMERAL
      set -xe
      EPHEMERAL_DIR="#{node['cluster']['ephemeral_dir']}"

      function set_imds_token(){
        if [ -z "${IMDS_TOKEN}" ];then
          IMDS_TOKEN=$(sudo curl --retry 3 --retry-delay 0 --fail -s -f -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 900" http://169.254.169.254/latest/api/token)
          if [ "${?}" -gt 0 ] || [ -z "${IMDS_TOKEN}" ]; then
            echo '[ERROR] Could not get IMDSv2 token. Instance Metadata might have been disabled or this is not an EC2 instance.'
            exit 1
          fi
        fi
      }
      function get_meta() {
          local IMDS_OUT=$(sudo curl --retry 3 --retry-delay 0 --fail -s -q -H "X-aws-ec2-metadata-token:${IMDS_TOKEN}" -f http://169.254.169.254/latest/${1})
          echo -n "${IMDS_OUT}"
      }
      function print_block_device_mapping(){
        echo 'block-device-mapping: '
        DEVICES=$(get_meta meta-data/block-device-mapping/)
        if [ -n "${DEVICES}" ]; then
          for DEVICE in ${DEVICES}; do
            echo -e '\t' ${DEVICE}: $(get_meta meta-data/block-device-mapping/${DEVICE})
          done
        else
          echo "NOT AVAILABLE"
        fi
      }

      # Check if instance has instance store
      if ls /dev/nvme* &>/dev/null; then
        # Ephemeral devices for NVME
        EPHEMERAL_DEVS=$(realpath --relative-to=/dev/ -P /dev/disk/by-id/nvme*Instance_Storage* | grep -v "*Instance_Storage*" | uniq)
      else
        # Ephemeral devices for not-NVME
        set_imds_token
        EPHEMERAL_DEVS=$(print_block_device_mapping | grep ephemeral | awk '{print $2}' | sed 's/sd/xvd/')
      fi

      NUM_DEVS=0
      set +e
      for EPHEMERAL_DEV in ${EPHEMERAL_DEVS}; do
        STAT_COMMAND="stat -t /dev/${EPHEMERAL_DEV}"
        if ${STAT_COMMAND} &>/dev/null; then
          let NUM_DEVS++
        fi
      done
      set -e

      if [ $NUM_DEVS -gt 0 ]; then
        mkdir -p ${EPHEMERAL_DIR}/test_dir
        touch ${EPHEMERAL_DIR}/test_dir/test_file
      fi
  EPHEMERAL
  user node['cluster']['cluster_user']
end
execute 'check setup-ephemeral service is enabled' do
  command "systemctl is-enabled setup-ephemeral"
end

###################
# Pcluster AWSBatch CLI
###################
if node['cluster']['scheduler'] == 'awsbatch' && node['cluster']['node_type'] == 'HeadNode'
  # Test that batch commands can be accessed without absolute path
  batch_cli_commands = %w(awsbkill awsbqueues awsbsub awsbhosts awsbout awsbstat)
  batch_cli_commands.each do |cli_commmand|
    bash "test_#{cli_commmand}" do
      cwd Chef::Config[:file_cache_path]
      code <<-BATCHCLI
        set -e
        source ~/.bash_profile
        #{cli_commmand} -h
      BATCHCLI
      user node['cluster']['cluster_user']
    end
  end
end

##################
# Verify enough space on AMIs
###################
unless node['cluster']['os'].end_with?("-custom")
  bash 'verify 10 GB of space left on root volume' do
    cwd Chef::Config[:file_cache_path]
    # This test assumes the df output is as follows:
    # $ df --block-size GB --output=avail /
    # Avail
    # 42GB
    code <<-CAPACITY_CHECK
      free_gigs="$(df --block-size GB --output=avail / | tail -n1 | cut -d G -f1)"
      if [ $free_gigs -lt 10 ]; then
        echo "Expected at least 10 GB of free space remaining on the root volume, but only found ${free_gigs}"
        exit 1
      fi
    CAPACITY_CHECK
    user node['cluster']['cluster_user']
  end
end

##################
# ipv4 gc_thresh
###################
expected_gc_settings = []
(1..3).each do |i|
  expected_gc_settings.append(node['cluster']['sysctl']['ipv4']["gc_thresh#{i}"])
end
expected_gc_settings = expected_gc_settings.join(',').to_s
bash 'check ipv4 gc_thresh is correctly configured' do
  cwd Chef::Config[:file_cache_path]
  code <<-GC
    set -e

    for i in {1..3}; do
      declare "actual_gc_thresh${i}=`cat /proc/sys/net/ipv4/neigh/default/gc_thresh${i}`"
    done
    actual_settings="${actual_gc_thresh1},${actual_gc_thresh2},${actual_gc_thresh3}"
    if [ "${actual_settings}" != "#{expected_gc_settings}" ]; then
            echo "ERROR: Incorrect gc_thresh settings!"
            echo "Expected "#{expected_gc_settings}" but actual is ${actual_settings}"
            exit 1
    fi
  GC
  user 'root'
end

##################
# Verify no MPICH packages
###################
bash 'verify no MPICH packages' do
  code <<-NOMPICH
    lib64_mpich_libs="$(ls 2>/dev/null /usr/lib64/mpich*)"
    lib_mpich_libs="$(ls 2>/dev/null /usr/lib/mpich*)"
    [ -z "${lib64_mpich_libs}" ] && [ -z "${lib_mpich_libs}" ]
  NOMPICH
end

##################
# Verify no FFTW packages
###################
unless node['cluster']['base_os'] == 'centos7'
  bash 'verify no FFTW packages' do
    code <<-NOFFTW
      lib64_fftw_libs="$(ls 2>/dev/null /usr/lib64/libfftw*)"
      lib_fftw_libs="$(ls 2>/dev/null /usr/lib/libfftw*)"
      [ -z "${lib64_fftw_libs}" ] && [ -z "${lib_fftw_libs}" ]
    NOFFTW
  end
end

###################
# Verify required service are enabled
###################
execute 'check supervisord service is enabled' do
  command "systemctl is-enabled supervisord"
end
execute 'check ec2blkdev service is enabled' do
  command "systemctl is-enabled ec2blkdev"
end

###################
# clusterstatusmgtd
###################
if node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] != 'awsbatch'
  execute "check clusterstatusmgtd is configured to be executed by supervisord" do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl status clusterstatusmgtd | grep RUNNING"
  end
end

###################
# Verify C-states are disabled
###################
if node['kernel']['machine'] == 'x86_64'
  execute 'Verify C-states are disabled' do
    command 'test "$(cat /sys/module/intel_idle/parameters/max_cstate)" = "1"'
  end
end
