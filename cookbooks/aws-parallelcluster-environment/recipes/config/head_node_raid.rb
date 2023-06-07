# frozen_string_literal: true

#
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

# Parse and get RAID shared directory info and turn into an array
raid_shared_dir = node['cluster']['raid_shared_dir']
manage_raid "add raid" do
  raid_shared_dir raid_shared_dir
  raid_type node['cluster']['raid_type']
  raid_vol_array node['cluster']['raid_vol_ids']
  action %i(mount export)
  not_if { raid_shared_dir.empty? }
end
