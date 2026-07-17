# frozen_string_literal: true

#
# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

module ErrorHandlers
  # Executes shell commands with retry logic and logging.
  class CommandRunner
    include Chef::Mixin::ShellOut

    DEFAULT_RETRIES = 10
    DEFAULT_RETRY_DELAY = 90
    DEFAULT_TIMEOUT = 30

    def initialize(log_prefix:)
      @log_prefix = log_prefix
    end

    def run_with_retries(command, description:, retries: DEFAULT_RETRIES, retry_delay: DEFAULT_RETRY_DELAY, timeout: DEFAULT_TIMEOUT)
      Chef::Log.info("#{@log_prefix} Executing: #{description}")
      max_attempts = retries + 1

      max_attempts.times do |attempt|
        attempt_num = attempt + 1
        Chef::Log.info("#{@log_prefix} Running command (attempt #{attempt_num}/#{max_attempts}): #{command}")
        result = shell_out(command, timeout: timeout)
        Chef::Log.info("#{@log_prefix} Command stdout: #{result.stdout}")
        Chef::Log.info("#{@log_prefix} Command stderr: #{result.stderr}")

        if result.exitstatus == 0
          Chef::Log.info("#{@log_prefix} Successfully executed: #{description}")
          return true
        end

        Chef::Log.warn("#{@log_prefix} Failed to #{description} (attempt #{attempt_num}/#{max_attempts})")

        if attempt_num < max_attempts
          Chef::Log.info("#{@log_prefix} Retrying in #{retry_delay} seconds...")
          sleep(retry_delay)
        end
      end

      Chef::Log.error("#{@log_prefix} Failed to #{description} after #{max_attempts} attempts")
      false
    end
  end
end
