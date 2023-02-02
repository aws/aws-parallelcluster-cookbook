# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-install
# Recipe:: gc_thresh_values
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

# Configure gc_thresh values to be consistent with alinux2 default values for performance at scale

def configure_gc_thresh_values
  (1..3).each do |i|
    sysctl "net.ipv4.neigh.default.gc_thresh#{i}" do
      value node['cluster']['sysctl']['ipv4']["gc_thresh#{i}"]
      action :apply
    end unless virtualized?
  end
end

configure_gc_thresh_values
