#
# Cookbook Name:: cfncluster
# Recipe:: tests
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

execute 'execute awscli' do
  command "aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
  user node['cfncluster']['cfn_cluster_user']
end

if node['cfncluster']['cfn_scheduler'] == 'sge'
  case node['cfncluster']['cfn_node_type']
  when 'MasterServer'
    execute 'execute qhost' do
      command "qhost -help"
      environment('PATH' => '/opt/sge/bin:/opt/sge/bin/lx-amd64:/bin:/usr/bin:$PATH', 'SGE_ROOT' => '/opt/sge')
      user node['cfncluster']['cfn_cluster_user']
    end

    execute 'execute qstat' do
      command "qstat -help"
      environment('PATH' => '/opt/sge/bin:/opt/sge/bin/lx-amd64:/bin:/usr/bin:$PATH', 'SGE_ROOT' => '/opt/sge')
      user node['cfncluster']['cfn_cluster_user']
    end

    execute 'execute qsub' do
      command "qsub -help"
      environment('PATH' => '/opt/sge/bin:/opt/sge/bin/lx-amd64:/bin:/usr/bin:$PATH', 'SGE_ROOT' => '/opt/sge')
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
  when 'ComputeFleet'
    execute 'ls slurm root' do
      command "ls /opt/slurm"
      user node['cfncluster']['cfn_cluster_user']
    end
  else
    raise "cfn_node_type must be MasterServer or ComputeFleet"
  end
end
