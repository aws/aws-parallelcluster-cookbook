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
  user node['cfncluster']['cfn_cluster_user']
end

execute 'execute awscli as root' do
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
end

[node['cfncluster']['cookbook_virtualenv_path'], node['cfncluster']['node_virtualenv_path']].each do |venv_path|
  execute "check #{venv_path} python version" do
    command %(#{venv_path}/bin/python -V | grep "Python #{node['cfncluster']['python-version']}")
  end
end

bash 'check awscli regions' do
  cwd Chef::Config[:file_cache_path]
  code <<-AWSREGIONS
    set -e
    export PATH="/usr/local/bin:/usr/bin/:$PATH"
    regions=($(#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region #{node['cfncluster']['cfn_region']} --query "Regions[].{Name:RegionName}" --output text))
    for region in "${regions[@]}"
    do
      #{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region "${region}" >/dev/null 2>&1
    done
  AWSREGIONS
end

###################
# SSH client conf
###################
execute 'grep ssh_config' do
  command 'grep -Pz "Match exec \"ssh_target_checker.sh %h\"\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null" /etc/ssh/ssh_config'
end

# Test only on MasterServer since on ComputeFleet an empty /home is mounted for the Kitchen tests run
if node['cfncluster']['cfn_node_type'] == 'MasterServer'
  execute 'ssh localhost as user' do
    command "ssh localhost hostname"
    environment('PATH' => '/usr/local/bin:/usr/bin:/bin:$PATH')
    user node['cfncluster']['cfn_cluster_user']
  end
end

###################
# munge
###################
if node['cfncluster']['cfn_scheduler'] == 'torque' || node['cfncluster']['cfn_scheduler'] == 'slurm'
  execute 'check munge installed' do
    command 'munge --version'
    user node['cfncluster']['cfn_cluster_user']
  end
end

###################
# SGE
###################
if node['cfncluster']['cfn_scheduler'] == 'sge'
  sge_bin_suffix = if arm_instance?
                     "arm64"
                   else
                     "amd64"
                   end
  sge_bin_paths = "/opt/sge/bin:/opt/sge/bin/lx-#{sge_bin_suffix}"
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer'
    execute 'execute qhost' do
      command "qhost -help"
      environment('PATH' => "#{sge_bin_paths}:/bin:/usr/bin:$PATH", 'SGE_ROOT' => '/opt/sge')
      user node['cfncluster']['cfn_cluster_user']
    end

    execute 'execute qstat' do
      command "qstat -help"
      environment('PATH' => "#{sge_bin_paths}:/bin:/usr/bin:$PATH", 'SGE_ROOT' => '/opt/sge')
      user node['cfncluster']['cfn_cluster_user']
    end

    execute 'execute qsub' do
      command "qsub -help"
      environment('PATH' => "#{sge_bin_paths}:/bin:/usr/bin:$PATH", 'SGE_ROOT' => '/opt/sge')
      user node['cfncluster']['cfn_cluster_user']
    end
  when 'ComputeFleet'
    execute 'ls sge root' do
      command "ls /opt/sge"
      user node['cfncluster']['cfn_cluster_user']
    end
  else
    raise "cfn_node_type must be MasterServer or ComputeFleet"
  end
end

###################
# Torque
###################
if node['cfncluster']['cfn_scheduler'] == 'torque'
  execute 'execute qstat' do
    command "qstat --version"
    environment('PATH' => '/opt/torque/bin:/opt/torque/sbin:$PATH')
    user node['cfncluster']['cfn_cluster_user']
  end

  execute 'execute qsub' do
    command "qsub --version"
    environment('PATH' => '/opt/torque/bin:/opt/torque/sbin:$PATH')
    user node['cfncluster']['cfn_cluster_user']
  end
end

###################
# Slurm
###################
if node['cfncluster']['cfn_scheduler'] == 'slurm'
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer'
    execute 'execute sinfo' do
      command "sinfo --help"
      environment('PATH' => '/opt/slurm/bin:/bin:/usr/bin:$PATH')
      user node['cfncluster']['cfn_cluster_user']
    end

    execute 'execute scontrol' do
      command "scontrol --help"
      environment('PATH' => '/opt/slurm/bin:/bin:/usr/bin:$PATH')
      user node['cfncluster']['cfn_cluster_user']
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
      user node['cfncluster']['cfn_cluster_user']
    end
  else
    raise "cfn_node_type must be MasterServer or ComputeFleet"
  end
end

###################
# Ganglia
###################
if node['init_package'] == 'init'
  gmond_check_command = "service #{node['cfncluster']['ganglia']['gmond_service']} status | grep -i running"
  gmetad_check_command = "service gmetad status | grep -i running"
elsif node['init_package'] == 'systemd'
  # $ systemctl show -p SubState <service>
  # SubState=Running
  gmond_check_command = "systemctl show -p SubState #{node['cfncluster']['ganglia']['gmond_service']} | grep -i running"
  gmetad_check_command = "systemctl show -p SubState gmetad | grep -i running"
end

case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  execute 'check gmond running' do
    command gmond_check_command
  end

  execute 'check gmetad running' do
    command gmetad_check_command
  end

  execute 'check ganglia webpage' do
    command 'curl --silent -L http://localhost/ganglia | grep "<title>Ganglia"'
  end
when 'ComputeFleet'
  execute 'check gmond running' do
    command gmond_check_command
  end
end

###################
# Amazon Time Sync
###################
if node['init_package'] == 'init'
  chrony_check_command = "service #{node['cfncluster']['chrony']['service']} status | grep -i running"
elsif node['init_package'] == 'systemd'
  # $ systemctl show -p SubState <service>
  # SubState=Running
  chrony_check_command = "systemctl show -p SubState #{node['cfncluster']['chrony']['service']} | grep -i running"
end

execute 'check chrony running' do
  command chrony_check_command
end

execute 'check chrony conf' do
  command "chronyc waitsync 30; chronyc tracking | grep -i reference | grep 169.254.169.123"
  user node['cfncluster']['cfn_cluster_user']
end

###################
# DCV
###################
if node['cfncluster']['cfn_node_type'] == "MasterServer" &&
   node['conditions']['dcv_supported'] &&
   (node['cfncluster']['dcv']['installed'] == 'yes' || node['cfncluster']['dcv']['installed'] == true)
  execute 'check dcv installed' do
    command 'dcv version'
    user node['cfncluster']['cfn_cluster_user']
  end
  if graphic_instance?
    execute "Ensure local users can access X server" do
      command %?DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') xhost | grep "LOCAL:$"?
    end
  end
  execute 'check DCV external authenticator python version' do
    command %(#{node['cfncluster']['dcv']['authenticator']['virtualenv_path']}/bin/python -V | grep "Python #{node['cfncluster']['python-version']}")
  end
  execute 'check screensaver screen lock disabled' do
    command 'gsettings get org.gnome.desktop.screensaver lock-enabled | grep false'
  end
  execute 'check non-screensaver screen lock disabled' do
    command 'gsettings get org.gnome.desktop.lockdown disable-lock-screen | grep true'
  end
end

###################
# EFA - Intel MPI
###################
if node['conditions']['efa_supported'] && node['conditions']['intel_mpi_supported']
  case node['cfncluster']['os']
  when 'alinux', 'centos7', 'alinux2'
    execute 'check efa rpm installed' do
      command "rpm -qa | grep libfabric && rpm -qa | grep efa-"
      user node['cfncluster']['cfn_cluster_user']
    end
    execute 'check intel mpi installed' do
      command "rpm -qa | grep intel-mpi"
      user node['cfncluster']['cfn_cluster_user']
    end
  when 'ubuntu1604', 'ubuntu1804'
    case node['cfncluster']['cfn_node_type']
    when 'MasterServer'
      execute 'check ptrace protection enabled' do
        command "sysctl kernel.yama.ptrace_scope | grep 'kernel.yama.ptrace_scope = 1'"
        user node['cfncluster']['cfn_cluster_user']
      end
    when 'ComputeFleet'
      execute 'check ptrace protection disabled' do
        command "sysctl kernel.yama.ptrace_scope | grep 'kernel.yama.ptrace_scope = 0'"
        user node['cfncluster']['cfn_cluster_user']
      end
    end
    execute 'check efa rpm installed' do
      command "dpkg -l | grep libfabric && dpkg -l | grep 'efa '"
      user node['cfncluster']['cfn_cluster_user']
    end
  end

  # Test only on MasterServer since on compute nodes we mount an empty /opt/intel drive in kitchen tests that
  # overrides intel binaries.
  if node['cfncluster']['cfn_node_type'] == 'MasterServer'
    bash 'check intel mpi version' do
      cwd Chef::Config[:file_cache_path]
      code <<-INTELMPI
        set -e
        # Initialize module
        # Unset MODULEPATH to force search path reinitialization when loading profile
        unset MODULEPATH
        # Must execute this in a bash script because source is a bash built-in function
        source /etc/profile.d/modules.sh
        module load intelmpi && mpirun --help | grep 'Version 2019 Update 7'
      INTELMPI
      user node['cfncluster']['cfn_cluster_user']
    end
  end
end

###################
# jq
###################
unless node['cfncluster']['os'].end_with?("-custom")
  bash 'execute jq' do
    cwd Chef::Config[:file_cache_path]
    code <<-JQMERGE
      set -e
      # Set PATH as in the UserData script of the CloudFormation template
      export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin"
      echo '{"cfncluster": {"cfn_region": "eu-west-3"}, "run_list": "recipe[aws-parallelcluster::sge_config]"}' > /tmp/dna.json
      echo '{ "cfncluster" : { "ganglia_enabled" : "yes" } }' > /tmp/extra.json
      jq --argfile f1 /tmp/dna.json --argfile f2 /tmp/extra.json -n '$f1 + $f2 | .cfncluster = $f1.cfncluster + $f2.cfncluster'
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
    driver_ver="#{node['cfncluster']['nvidia']['driver_version']}"
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

bash 'test CUDA install' do
  cwd Chef::Config[:file_cache_path]
  code <<-TESTCUDA
    has_gpu=$(lspci | grep -o "NVIDIA")
    if [ -z "$has_gpu" ]; then
      echo "No GPU detected, no test needed."
      exit 0
    fi

    set -e
    cuda_ver="#{node['cfncluster']['nvidia']['cuda_version']}"
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
if node['conditions']['intel_hpc_platform_supported'] && node['cfncluster']['enable_intel_hpc_platform'] == 'true'
  execute "check-intel-python2" do
    # Output code will be 1 if version is different
    command "rpm -q intelpython2 | grep #{node['cfncluster']['intelpython2']['version']}"
  end
  execute "check-intel-python3" do
    # Output code will be 1 if version is different
    command "rpm -q intelpython3 | grep #{node['cfncluster']['intelpython3']['version']}"
  end
end

###################
# FSx Lustre
###################
if node['conditions']['lustre_supported']
  case node['cfncluster']['os']
  when 'alinux', 'centos7'
    execute 'check for lustre libraries' do
      command "rpm -qa | grep lustre-client"
      user node['cfncluster']['cfn_cluster_user']
    end
  when 'ubuntu1604', 'ubuntu1804'
    execute 'check for lustre libraries' do
      command "dpkg -l | grep lustre"
      user node['cfncluster']['cfn_cluster_user']
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
if node['cfncluster']['cfn_node_type'] == 'ComputeFleet'
  execute 'check for nfs client protocol' do
    command "nfsstat -m | grep vers=4"
    user node['cfncluster']['cfn_cluster_user']
  end
elsif node['cfncluster']['cfn_node_type'] == 'MasterServer'
  execute 'check for nfs server protocol' do
    command "rpcinfo -p localhost | awk '{print $2$5}' | grep 4nfs"
    user node['cfncluster']['cfn_cluster_user']
  end
end

###################
# ulimit
###################
unless node['cfncluster']['os'].end_with?("-custom")
  bash 'test soft ulimit nofile' do
    code "if (($(ulimit -Sn) < 8192)); then exit 1; fi"
    user node['cfncluster']['cfn_cluster_user']
  end
end
