
module WriteChefError
  class WriteChefError < Chef::Handler
    def report
      if run_status.failed?
        Mixlib::ShellOut.new("echo 'Failed when running chef recipes: #{run_status.formatted_exception}' > /var/log/parallelcluster/headnode_bootstrap_error_msg").run_command
      end
    end
  end
end
