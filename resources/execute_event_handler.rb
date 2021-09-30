# frozen_string_literal: true

resource_name :execute_event_handler
provides :execute_event_handler

# Resource to execute BYOS event handler

property :event_name, String, name_property: true
property :event_command, String, required: false

default_action :run

action :run do
  if new_resource.event_command.nil?
    Chef::Log.info("No command defined for Event #{new_resource.event_name}, noop")
    return
  end

  event_log = '/var/log/parallelcluster/byos-plugin.log'
  event_cwd = '/home/byos'
  event_user = 'byos'
  event_env = build_env
  event_log_prefix_error = "[%Y-%m-%d %H:%M:%S] ERROR [#{new_resource.event_name}]"
  event_log_prefix_info = "[%Y-%m-%d %H:%M:%S] INFO [#{new_resource.event_name}]"
  Chef::Log.info("Executing Event #{new_resource.event_name}, with user (#{event_user}), cwd (#{event_cwd}), command (#{new_resource.event_command}), log (#{event_log})")
  # shellout https://github.com/chef/mixlib-shellout
  # switch stderr/stdout with (2>&1 1>&3-), process error (now on stdout), switch back stdout/stderr with (3>&1 1>&2) and then process output
  cmd = Mixlib::ShellOut.new("set -o pipefail; { (bash #{new_resource.event_command}) 2>&1 1>&3- | ts '#{event_log_prefix_error}' | tee -a #{event_log}; } " \
    "3>&1 1>&2 | ts '#{event_log_prefix_info}' | tee -a #{event_log}", user: event_user, env: event_env, cwd: event_cwd)
  cmd.run_command

  if cmd.error?
    raise "Expected Event #{new_resource.event_name} to exit with #{cmd.valid_exit_codes.inspect}, but received '#{cmd.exitstatus}', complete log in #{event_log}\n #{format_for_exception(cmd)}"
  end
end

action_class do
  def format_for_exception(cmd)
    "---- STDERR for #{new_resource.event_name} Event ----\n" \
    "#{cmd.stderr.strip}\n" \
    "---- End STDERR for #{new_resource.event_name} Event ----\n"
  end

  def build_env
    env = {}

    # PCLUSTER_CLUSTER_CONFIG
    cluster_config = node.dig(:cluster, :cluster_config_path)
    env['PCLUSTER_CLUSTER_CONFIG'] = cluster_config if cluster_config && !cluster_config.empty?

    # TODO
    # PCLUSTER_LAUNCH_TEMPLATES
    # PCLUSTER_DYNAMODB_TABLE
    # PCLUSTER_CLUSTER_NAME
    # PCLUSTER_CFN_STACK_ARN
    # PCLUSTER_BYOS_CFN_SUBSTACK_ARN
    # PCLUSTER_BYOS_CFN_SUBSTACK_OUTPUTS
    # PCLUSTER_SHARED_PACKAGES_DIR
    # PCLUSTER_CFN_STACK_ARN

    # PCLUSTER_AWS_REGION
    aws_region = node.dig(:ec2, :region)
    env['PCLUSTER_AWS_REGION'] = aws_region if aws_region && !aws_region.empty?

    # PCLUSTER_EC2_INSTANCE_TYPE
    ec2_instance_type = node.dig(:ec2, :instance_type)
    env['PCLUSTER_EC2_INSTANCE_TYPE'] = ec2_instance_type if ec2_instance_type && !ec2_instance_type.empty?

    # PCLUSTER_OS
    os = node.dig(:cluster, :config, :Image, :Os)
    env['PCLUSTER_OS'] = os if os && !os.empty?

    # PCLUSTER_ARCH
    arch = node.dig(:cpu, :architecture)
    env['PCLUSTER_ARCH'] = arch if arch && !arch.empty?

    # PCLUSTER_VERSION

    case node['cluster']['node_type']
    when 'HeadNode'
      # PCLUSTER_HEADNODE_PRIVATE_IP

      # PCLUSTER_HEADNODE_HOSTNAME
      headnode_hostname = node.dig(:ec2, :hostname)
      env['PCLUSTER_HEADNODE_HOSTNAME'] = headnode_hostname if headnode_hostname && !headnode_hostname.empty?
    when 'ComputeFleet'
      # PCLUSTER_QUEUE_NAME
      # PCLUSTER_COMPUTE_RESOURCE_NAME
    end

    # PCLUSTER_CLUSTER_CONFIG_OLD

    env
  end
end
