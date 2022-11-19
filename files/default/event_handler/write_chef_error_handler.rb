
module WriteChefError
  class WriteChefError < Chef::Handler
    def report
      if run_status.failed?
        error_file = '/var/log/parallelcluster/bootstrap_error_msg'
        unless File.exist?(error_file)
          message = "Failed when running chef recipes (If --rollback-on-failure was set to false, more details can be found in /var/log/chef-client.log and /var/log/cloud-init-output.log.):"
          Mixlib::ShellOut.new("echo '#{message}' '#{run_status.formatted_exception}' > '#{error_file}'").run_command
        end
      end
    end
  end
end
