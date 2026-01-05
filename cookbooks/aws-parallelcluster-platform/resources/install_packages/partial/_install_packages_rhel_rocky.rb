# frozen_string_literal: true

#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

action :install do
  ruby_block 'install_packages_with_metadata_refresh' do
    block do
      packages = Array(new_resource.packages)

      Chef::Log.info("Installing packages: #{packages.join(', ')}")

      on_retry = lambda do |_attempt, _exception|
        # This cleanup forces DNF to re-evaluate available mirrors
        # and which mirror to use on the next attempt.
        run_cmd('dnf clean metadata')
      end

      with_retries(
        max_retries: 10,
        retry_delay: 5,
        on_retry: on_retry
      ) do
        # --refresh forces DNF to refresh the metadata from the mirror it's currently using.
        run_cmd("dnf install -y --refresh #{packages.join(' ')}", raise_on_error: true)
        Chef::Log.info("Package installation succeeded")
      end
    end
  end
end
