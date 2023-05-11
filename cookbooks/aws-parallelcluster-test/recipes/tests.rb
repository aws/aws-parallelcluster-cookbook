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

###################
# SSH client conf
###################
# Test only on head node since on compute fleet an empty /home is mounted for the Kitchen tests run
if node['cluster']['node_type'] == 'HeadNode'
  execute 'ssh localhost as user' do
    command "ssh localhost hostname"
    environment('PATH' => '/usr/local/bin:/usr/bin:/bin:$PATH')
    user node['cluster']['cluster_user']
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

