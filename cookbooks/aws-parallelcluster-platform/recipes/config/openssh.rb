# frozen_string_literal: true

# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Install SSH target checker
template '/usr/bin/ssh_target_checker.sh' do
  source 'openssh/ssh_target_checker.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(vpc_cidr_list: get_vpc_cidr_list)
end
