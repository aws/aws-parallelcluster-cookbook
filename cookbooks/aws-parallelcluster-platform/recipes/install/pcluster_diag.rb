# frozen_string_literal: true
#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Stages the pcluster-diag source on the node and exposes `pcluster-diag` on PATH.

source_dir = "#{node['cluster']['sources_dir']}/pcluster-diag"
virtualenv_path = cookbook_virtualenv_path
bin_path = '/usr/local/bin/pcluster-diag'

# pcluster-diag runs with the cookbook_virtualenv interpreter, so skip whenever that venv is not created.
return if redhat_on_docker?

# Per-node copy of the tool source, baked into the AMI.
remote_directory source_dir do
  source 'pcluster-diag'
  mode '0755'
  action :create
  recursive true
end

# Wrapper on PATH that runs the tool from source with the cookbook_virtualenv interpreter.
template bin_path do
  source 'pcluster-diag/pcluster-diag.erb'
  variables(
    source_dir: source_dir,
    virtualenv_path: virtualenv_path
  )
  owner 'root'
  group 'root'
  mode '0744'
end
