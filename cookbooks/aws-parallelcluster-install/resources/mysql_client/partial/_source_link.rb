# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

action :create_source_link do
  # Add MySQL source file
  file "#{node['cluster']['sources_dir']}/mysql_source_code.txt" do
    content %(You can get MySQL source code here:

#{node['cluster']['mysql']['package']['source']}
)
    owner 'root'
    group 'root'
    mode '0644'
  end
end
