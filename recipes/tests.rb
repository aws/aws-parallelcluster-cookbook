# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: tests
#
# Copyright 2013-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

###################
# AWS Cli
###################
execute 'execute awscli as user' do
  command "aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
  user node['cluster']['cluster_user']
end

execute 'execute awscli as root' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
end

[node['cluster']['cookbook_virtualenv_path'], node['cluster']['node_virtualenv_path']].each do |venv_path|
  execute "check #{venv_path} python version" do
    command %(#{venv_path}/bin/python -V | grep "Python #{node['cluster']['python-version']}")
  end
end

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
# munge
###################
if node['cluster']['scheduler'] == 'slurm'
  execute 'check munge installed' do
    command 'munge --version'
    user node['cluster']['cluster_user']
  end
end

###################
# Slurm
###################
if node['cluster']['scheduler'] == 'slurm'
  case node['cluster']['node_type']
  when 'HeadNode'
    execute 'execute sinfo' do
      command "sinfo --help"
      environment('PATH' => '/opt/slurm/bin:/bin:/usr/bin:$PATH')
      user node['cluster']['cluster_user']
    end

    execute 'execute scontrol' do
      command "scontrol --help"
      environment('PATH' => '/opt/slurm/bin:/bin:/usr/bin:$PATH')
      user node['cluster']['cluster_user']
    end

    execute 'check-slurm-accounting-mysql-plugins' do
      command "ls /opt/slurm/lib/slurm/ | grep accounting_storage_mysql"
    end

    execute 'check-slurm-jobcomp-mysql-plugins' do
      command "ls /opt/slurm/lib/slurm/ | grep jobcomp_mysql"
    end

    execute 'check-slurm-pmix-plugins' do
      command 'ls /opt/slurm/lib/slurm/ | grep pmix'
    end
    execute 'ensure-pmix-shared-library-can-be-found' do
      command '/opt/pmix/bin/pmix_info'
    end
  when 'ComputeFleet'
    execute 'ls slurm root' do
      command "ls /opt/slurm"
      user node['cluster']['cluster_user']
    end
  else
    raise "node_type must be HeadNode or ComputeFleet"
  end
end

###################
# Amazon Time Sync
###################
case node['init_package']
when 'init'
  get_chrony_status_command = "service #{node['cluster']['chrony']['service']} status"
when 'systemd'
  # $ systemctl show -p SubState <service>
  # SubState=Running
  get_chrony_status_command = "systemctl show -p SubState #{node['cluster']['chrony']['service']}"
end
chrony_check_command = "#{get_chrony_status_command} | grep -i running"

ruby_block 'log_chrony_status' do
  block do
    case node['init_package']
    when 'init'
      get_chrony_service_log_command = "cat /var/log/messages | grep -i '#{node['cluster']['chrony']['service']}'"
    when 'systemd'
      get_chrony_service_log_command = "journalctl -u #{node['cluster']['chrony']['service']}"
    end
    chrony_log = shell_out!(get_chrony_service_log_command).stdout
    Chef::Log.debug("chrony service log: #{chrony_log}")
    chrony_status = shell_out!(get_chrony_status_command).stdout
    Chef::Log.debug("chrony status is #{chrony_status}")
  end
end

execute 'check chrony running' do
  command chrony_check_command
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
  execute 'check systemd default runlevel' do
    command "systemctl get-default | grep -i graphical.target"
  end
  if graphic_instance?
    execute "Ensure local users can access X server" do
      command %?DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') xhost | grep "LOCAL:$"?
    end
  end
  if node['cluster']['os'] == "ubuntu1804" || node['cluster']['os'] == "alinux2"
    execute 'check gdm service is running' do
      command "systemctl show -p SubState gdm | grep -i running"
    end
  end
elsif node['init_package'] == 'systemd' && node['conditions']['ami_bootstrapped']
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
  case node['cluster']['os']
  when 'alinux2', 'centos7', 'centos8'
    execute 'check efa rpm installed' do
      command "rpm -qa | grep libfabric && rpm -qa | grep efa-"
      user node['cluster']['cluster_user']
    end
    execute 'check intel mpi installed' do
      command "rpm -qa | grep intel-mpi"
      user node['cluster']['cluster_user']
    end
  when 'ubuntu1804'
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
    execute 'check efa rpm installed' do
      command "dpkg -l | grep libfabric && dpkg -l | grep 'efa '"
      user node['cluster']['cluster_user']
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
# EFA - GDR (GPUDirect RDMA)
###################
if node['conditions']['efa_supported'] && efa_gdr_enabled?
  execute 'check efa gdr installed' do
    command "modinfo efa | grep 'gdr:\ *Y'"
    user node['cluster']['cluster_user']
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
      jq --argfile f1 /tmp/dna.json --argfile f2 /tmp/extra.json -n '$f1 + $f2 | .cluster = $f1.cluster + $f2.cluster'
    JQMERGE
  end
end

###################
# NVIDIA - CUDA
###################
bash 'test nvidia driver install' do
  cwd Chef::Config[:file_cache_path]
  code <<-TESTNVIDIA
    has_gpu=$(lspci | grep -o "NVIDIA")
    if [ -z "$has_gpu" ]; then
      echo "No GPU detected, no test needed."
      exit 0
    fi

    set -e
    driver_ver="#{node['cluster']['nvidia']['driver_version']}"
    export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin"

    # Test NVIDIA Driver installation
    echo "Testing NVIDIA driver install..."
    # grep driver version from nvidia-smi output. If driver is not installed nvidia-smi command will fail
    driver_output=$(nvidia-smi | grep -E -o "Driver Version: [0-9.]+")
    if [ "$driver_output" != "Driver Version: $driver_ver" ]; then
      echo "NVIDIA driver installed incorrectly! Installed $driver_output but expected version $driver_ver"
      exit 1
    else
      echo "Correctly installed NVIDIA $driver_output"
    fi
  TESTNVIDIA
end

unless node['cluster']['base_os'] == 'alinux' && get_nvswitches > 1
  bash 'test CUDA install' do
    cwd Chef::Config[:file_cache_path]
    code <<-TESTCUDA
      has_gpu=$(lspci | grep -o "NVIDIA")
      if [ -z "$has_gpu" ]; then
        echo "No GPU detected, no test needed."
        exit 0
      fi

      set -e
      cuda_ver="#{node['cluster']['nvidia']['cuda_version']}"
      # Test CUDA installation
      echo "Testing CUDA install with nvcc..."
      export PATH=/usr/local/cuda-$cuda_ver/bin:$PATH
      export LD_LIBRARY_PATH=/usr/local/cuda-$cuda_ver/lib64:$LD_LIBRARY_PATH
      # grep CUDA version from nvcc output. If CUDA is not installed nvcc command will fail
      cuda_output=$(nvcc -V | grep -E -o "release [0-9]+.[0-9]+")
      if [ "$cuda_output" != "release $cuda_ver" ]; then
        echo "CUDA installed incorrectly! Installed $cuda_output but expected $cuda_ver"
        exit 1
      else
        echo "CUDA nvcc test passed, $cuda_output"
      fi

      # Test deviceQuery
      echo "Testing CUDA install with deviceQuery..."
      /usr/local/cuda-$cuda_ver/extras/demo_suite/deviceQuery | grep -o "Result = PASS"
      echo "CUDA deviceQuery test passed"
      echo "Correctly installed CUDA $cuda_output"
    TESTCUDA
  end
end
###################
# FabricManager
###################
if get_nvswitches > 1
  bash 'test fabric-manager daemon' do
    cwd Chef::Config[:file_cache_path]
    code <<-TESTFM
      set -e
      systemctl show -p SubState nvidia-fabricmanager | grep -i running
      echo "NVIDIA Fabric Manager service correctly started"
    TESTFM
  end
end

###################
# CloudWatch
###################
# Verify that the CloudWatch agent's status can be queried. It should always be stopped during kitchen tests.
execute 'cloudwatch-agent-status' do
  user 'root'
  command "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep stopped"
end

###################
# Intel Python
###################
# Intel Python Libraries
if node['conditions']['intel_hpc_platform_supported'] && node['cluster']['enable_intel_hpc_platform'] == 'true'
  %w[2 3].each do |python_version|
    intel_package_version = node['cluster']["intelpython#{python_version}"]['version']
    execute "check-intel-python#{python_version}-rpm" do
      # Output code will be 1 if version is different
      command "rpm -q intelpython#{python_version} | grep #{intel_package_version}"
    end
    execute "check-intel-python#{python_version}-executable" do
      command "/opt/intel/intelpython#{python_version}/bin/python -V"
    end
  end
end

###################
# FSx Lustre
###################
if node['conditions']['lustre_supported']
  case node['cluster']['os']
  when 'centos7'
    execute 'check for lustre libraries' do
      command "rpm -qa | grep lustre-client"
      user node['cluster']['cluster_user']
    end
  when 'ubuntu1804'
    execute 'check for lustre libraries' do
      command "dpkg -l | grep lustre"
      user node['cluster']['cluster_user']
    end
  end
end

###################
# Bridge Network Interface
###################
if node['platform'] == 'centos'
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
unless node['platform'] == 'ubuntu' && node['platform_version'].to_d == 16.04.to_d
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
# PIP
###################
require 'chef/mixin/shell_out'

virtual_envs = [node['cluster']['node_virtualenv_path'], node['cluster']['cookbook_virtualenv_path']]

virtual_envs.each do |virtual_env|
  ruby_block 'check pip version' do
    block do
      pip_version = nil
      pip_show = shell_out!("#{virtual_env}/bin/pip show pip").stdout.strip
      pip_show.split(/\n+/).each do |line|
        pip_version = line.split(/\s+/)[1] if line.start_with?('Version:')
      end
      Chef::Log.debug("pip version in virtualenv #{virtual_env} is #{pip_version}")
      if !pip_version || pip_version.to_f < 19.3
        # pip versions >= 19.3 is required to enable installation of python wheel binaries on Graviton
        raise "pip version in virtualenv #{virtual_env} must be greater than 19.3"
      end
    end
  end
end

###################
# ARM - PL
###################
if node['conditions']['arm_pl_supported']
  bash 'check gcc version and module loaded' do
    cwd Chef::Config[:file_cache_path]
    code <<-ARMPL
      set -e
      # Initialize module
      unset MODULEPATH
      source /etc/profile.d/modules.sh
      (module avail)2>&1 | grep armpl/#{node['cluster']['armpl']['version']}
      module load armpl/#{node['cluster']['armpl']['version']}
      gcc --version | grep #{node['cluster']['armpl']['gcc']['major_minor_version']}
      (module list)2>&1 | grep armpl/#{node['cluster']['armpl']['version']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}
      (module list)2>&1 | grep armpl/gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}
    ARMPL
    user node['cluster']['cluster_user']
  end
end

###################
# Pcluster AWSBatch CLI
###################
if node['cluster']['scheduler'] == 'awsbatch' && node['cluster']['node_type'] == 'HeadNode'
  # Test that batch commands can be accessed without absolute path
  batch_cli_commands = %w[awsbkill awsbqueues awsbsub awsbhosts awsbout awsbstat]
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

###################
# Python
###################
execute 'check python3 installed' do
  command "which python3"
  user node['cluster']['cluster_user']
end
