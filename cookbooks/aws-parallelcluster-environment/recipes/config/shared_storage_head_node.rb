# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Export /home
nfs_export "/home" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end unless on_docker?

# Export /opt/parallelcluster/shared
nfs_export node['cluster']['shared_dir'] do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end unless on_docker?

# Export /opt/intel if it exists
nfs_export "/opt/intel" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
  only_if { ::File.directory?("/opt/intel") }
end unless on_docker?
