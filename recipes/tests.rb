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

execute 'execute awscli as user' do
  command "aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
  user node['cfncluster']['cfn_cluster_user']
end

execute 'execute awscli as root' do
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws --version"
  environment('PATH' => '/usr/local/bin:/usr/bin/:$PATH')
end

bash 'check awscli regions' do
  cwd Chef::Config[:file_cache_path]
  code <<-AWSREGIONS
    export PATH="/usr/local/bin:/usr/bin/:$PATH"
    regions=($(#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region us-east-1 --query "Regions[].{Name:RegionName}" --output text))
    for region in "${regions[@]}"
    do
      #{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region "${region}" >/dev/null 2>&1 || exit 1
    done
  AWSREGIONS
end

unless node['cfncluster']['os'].end_with?("-custom")
  bash 'test soft ulimit nofile' do
    code "if (($(ulimit -Sn) < 10000)); then exit 1; fi"
    user node['cfncluster']['cfn_cluster_user']
  end
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

if node['cfncluster']['cfn_node_type'] == "MasterServer" and node['cfncluster']['os'] == 'centos7' and node['cfncluster']['dcv']['installed'] == 'yes'
  execute 'check dcv installed' do
    command 'dcv version'
  end
end


unless node['cfncluster']['cfn_region'].start_with?("cn-")
  case node['cfncluster']['os']
  when 'alinux', 'centos7'
    execute 'check efa rpm installed' do
      command "rpm -qa | grep libfabric && rpm -qa | grep efa-"
      user node['cfncluster']['cfn_cluster_user']
    end
  when 'ubuntu1604'
    execute 'check efa rpm installed' do
      command "dpkg -l | grep libfabric && dpkg -l | grep 'efa '"
      user node['cfncluster']['cfn_cluster_user']
    end
  end
end

unless node['cfncluster']['os'].end_with?("-custom")
  bash 'execute jq' do
    cwd Chef::Config[:file_cache_path]
    code <<-JQMERGE
      # Set PATH as in the UserData script of the CloudFormation template
      export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin"
      echo '{"cfncluster": {"cfn_region": "eu-west-3"}, "run_list": "recipe[aws-parallelcluster::sge_config]"}' > /tmp/dna.json
      echo '{ "cfncluster" : { "ganglia_enabled" : "yes" } }' > /tmp/extra.json
      jq --argfile f1 /tmp/dna.json --argfile f2 /tmp/extra.json -n '$f1 + $f2 | .cfncluster = $f1.cfncluster + $f2.cfncluster' || exit 1
    JQMERGE
  end
end
