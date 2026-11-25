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

require 'chef/handler'
require 'chef/mixin/shell_out'

module ErrorHandlers
  # Chef exception handler logging why the systemd services that made the run fail are not running.
  #
  # A run fails on a service either because the service resource could not start it (e.g. gdrcopy), or because a
  # `systemctl is-active` check found it not running after its start (e.g. slurmd, whose start does not report
  # failures). For each of these services, the handler logs `systemctl status` and the end of its journal to the
  # Chef log, which is shipped to CloudWatch, so the cause is kept even when the node is terminated afterwards.
  #
  # The handler only logs: it never fails, so it cannot hide the original failure or stop the other handlers.
  class ServiceFailureHandler < Chef::Handler
    include Chef::Mixin::ShellOut

    JOURNAL_LINES = 100
    COMMAND_TIMEOUT_SECONDS = 30
    # A `systemctl is-active` check, e.g. "systemctl is-active --quiet slurmd.service": captures the unit.
    IS_ACTIVE_CHECK = /\bsystemctl\s+is-active\b(?:\s+-\S+)*\s+(?<unit>[^\s;&|]+)/.freeze

    def report
      failed_units.each { |unit| log_unit_status(unit) }
    rescue => e
      Chef::Log.warn("#{log_prefix} Failed with error: #{e.message}")
    end

    # Returns the systemd units of the failed resources that start or check a service.
    def failed_units
      action_collection.filtered_collection(
        up_to_date: false, skipped: false, updated: false, failed: true, unprocessed: false
      ).map { |action_record| unit_of(action_record.new_resource) }.compact.uniq
    end

    # Returns the systemd unit that ``resource`` starts or checks, or nil if it is not about a service.
    def unit_of(resource)
      case resource.resource_name
      when :service
        resource.service_name
      when :systemd_unit
        resource.unit_name
      when :execute
        Array(resource.command).join(' ')[IS_ACTIVE_CHECK, 'unit']
      end
    end

    def log_unit_status(unit)
      Chef::Log.error("#{log_prefix} Service #{unit} is not running, its status and the last #{JOURNAL_LINES} lines of its journal follow")
      log_command_output('systemctl', 'status', unit, '--no-pager', '--full')
      log_command_output('journalctl', '--unit', unit, '--lines', JOURNAL_LINES.to_s, '--no-pager')
    end

    def log_command_output(*command)
      result = shell_out(*command, timeout: COMMAND_TIMEOUT_SECONDS)
      Chef::Log.error("#{log_prefix} Output of '#{command.join(' ')}':\n#{result.stdout}#{result.stderr}")
    rescue => e
      Chef::Log.warn("#{log_prefix} Could not run '#{command.join(' ')}': #{e.message}")
    end

    def log_prefix
      @log_prefix ||= "#{self.class.name}:"
    end
  end
end
