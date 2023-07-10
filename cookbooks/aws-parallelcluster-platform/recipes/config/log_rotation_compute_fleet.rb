# frozen_string_literal: true

#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# TODO: move the logrotate configuration of the various services to the corresponding recipes/cookbooks.
logrotate_conf_dir = node['cluster']['logrotate_conf_dir']
logrotate_template_dir = 'log_rotation/'

config_files = %w(
    parallelcluster_cloud_init_output_log_rotation
  )

if node['cluster']['scheduler'] == 'slurm'
  config_files += %w(
    parallelcluster_computemgtd_log_rotation
    parallelcluster_slurmd_log_rotation
  )
end

config_files.each do |config_file|
  output_file = logrotate_conf_dir + config_file
  template_file = logrotate_template_dir + config_file + '.erb'
  template output_file do
    source template_file
    mode '0644'
  end
end
