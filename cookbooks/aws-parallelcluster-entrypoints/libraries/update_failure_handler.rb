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

require 'chef/handler'
require_relative 'command_runner'

module ErrorHandlers
  # Chef exception handler for cluster update failures.
  #
  # This handler is triggered when either the update or update-compute-fleet recipe fails.
  # It performs recovery actions to restore the cluster to a consistent state:
  # 1. Logs information about the update failure including which resources succeeded before failure.
  # 2. Cleans up DNA files shared with compute nodes, if cleanup_dna_files=true.
  # 3. Starts clustermgtd, if start_clustermgtd=true.
  #
  # Only runs on HeadNode - compute and login nodes skip this handler.
  class UpdateFailureHandler < Chef::Handler
    def initialize(config = {})
      @cleanup_dna_files = config.fetch(:cleanup_dna_files, false)
      @start_clustermgtd = config.fetch(:start_clustermgtd, false)
      super()
    end

    def report
      Chef::Log.info("#{log_prefix} Started with parameters @cleanup_dna_files=#{@cleanup_dna_files}, @start_clustermgtd=#{@start_clustermgtd}")

      unless node_type == 'HeadNode' && scheduler == 'slurm'
        Chef::Log.info("#{log_prefix} Node type is #{node_type} and scheduler is #{scheduler}, recovery from update failure only executes on the HeadNode with slurm scheduler")
        return
      end

      begin
        write_error_report
        run_recovery
        Chef::Log.info("#{log_prefix} Completed successfully")
      rescue => e
        Chef::Log.error("#{log_prefix} Failed with error: #{e.message}")
        Chef::Log.error("#{log_prefix} Backtrace: #{e.backtrace.join("\n")}")
      end
    end

    def write_error_report
      Chef::Log.info("#{log_prefix} Update failed on #{node_type} due to: #{run_status.exception}")
      Chef::Log.info("#{log_prefix} Resources that have been successfully executed before the failure:")
      run_status.updated_resources.each do |resource|
        Chef::Log.info("#{log_prefix}   - #{resource}")
      end
    end

    def run_recovery
      Chef::Log.info("#{log_prefix} Running recovery commands")
      start_clustermgtd if @start_clustermgtd
      cleanup_dna_files if @cleanup_dna_files
    end

    def cleanup_dna_files
      marker = "#{cluster_attributes['shared_dir']}/update_failed_marker"
      begin
        if ::File.exist?(marker)
          # Marker exists from previous update failure — this is a rollback failure, keep DNA files
          Chef::Log.info("#{log_prefix} Rollback failure detected (marker found at #{marker}), keeping DNA files")
          ::File.delete(marker)
        else
          # No marker — this is an update failure, clean up DNA files and write marker
          Chef::Log.info("#{log_prefix} Update failure detected (no marker at #{marker}), cleaning up DNA files")
          command = "#{cookbook_virtualenv_path}/bin/python #{cluster_attributes['scripts_dir']}/manage_fleet_dna.py --region #{cluster_attributes['region']} --cleanup"
          command_runner.run_with_retries(command, description: "cleanup DNA files")
          ::File.write(marker, '')
        end
      rescue => e
        # If marker I/O fails, fall back to deleting DNA files
        Chef::Log.warn("#{log_prefix} Error during marker check (#{e.message}), falling back to cleaning up DNA files")
        command = "#{cookbook_virtualenv_path}/bin/python #{cluster_attributes['scripts_dir']}/manage_fleet_dna.py --region #{cluster_attributes['region']} --cleanup"
        command_runner.run_with_retries(command, description: "cleanup DNA files")
      end
    end

    def start_clustermgtd
      command = "#{cookbook_virtualenv_path}/bin/supervisorctl start clustermgtd"
      command_runner.run_with_retries(command, description: "start clustermgtd")
    end

    def cluster_attributes
      run_status.node['cluster']
    end

    def node_type
      cluster_attributes['node_type']
    end

    def scheduler
      cluster_attributes['scheduler']
    end

    def cookbook_virtualenv_path
      "#{cluster_attributes['system_pyenv_root']}/versions/#{cluster_attributes['python-version']}/envs/cookbook_virtualenv"
    end

    def resource_succeeded?(resource_name)
      %i(updated up_to_date).include?(resource_status(resource_name))
    end

    def resource_status(resource_name)
      # Use action_collection directly (inherited from Chef::Handler)
      action_records = action_collection.filtered_collection
      record = action_records.find { |r| r.new_resource.resource_name == :execute && r.new_resource.name == resource_name }
      record ? record.status : :not_executed
    end

    def command_runner
      @command_runner ||= CommandRunner.new(log_prefix: log_prefix)
    end

    def log_prefix
      @log_prefix ||= "#{self.class.name}:"
    end
  end
end
