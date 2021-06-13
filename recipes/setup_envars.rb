# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: setup_envars
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

ruby_block 'Configure environment variable: PATH' do
  block do
    directories = %w[/usr/local/sbin /usr/local/bin /sbin /bin /usr/sbin /usr/bin /opt/aws/bin]
    directories.each do |directory|
      ENV['PATH'] = "#{ENV['PATH']}:#{directory}" unless ":#{ENV['PATH']}:".include?(":#{directory}:")
    end
  end
end
