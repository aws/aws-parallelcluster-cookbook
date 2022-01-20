module WriteChefError
  class WriteChefError < Chef::Handler
    def report
      if run_status.failed?
        error_message_mapping = { "[HeadInit]" => "HeadInit",
                                  "[HeadConfigure]" => "HeadConfigure",
                                  "[HeadFinalize]" => "HeadFinalize",
                                  "[ComputeInit]" => "ComputeInit",
                                  "[ComputeConfigure]" => "ComputeConfigure",
                                  "[ComputeFinalize]" => "ComputeFinalize",
                                  "[HeadClusterUpdate]" => "HeadClusterUpdate",
        }
        error_message_mapping.each do |key, vals|
          if run_status.formatted_exception.include? key
            message = "Failed when running #{vals} for the configured scheduler plugin." \
            " Additional info can be found in /var/log/chef-client.log, /var/log/parallelcluster/scheduler-plugin.out.log" \
            " and /var/log/parallelcluster/scheduler-plugin.err.log."
            Mixlib::ShellOut.new("echo #{message} > /var/log/parallelcluster/chef_error_msg").run_command
          end
        end
      end
    end
  end
end
