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

  event_log = node['cluster']['byos']['handler_log']
  event_cwd = node['cluster']['byos']['home']
  event_user = node['cluster']['byos']['user']
  event_env = build_env
  event_log_prefix_error = "[%Y-%m-%dT%H:%M:%S%z] [#{new_resource.event_name}] ERROR: "
  event_log_prefix_info = "[%Y-%m-%dT%H:%M:%S%z] [#{new_resource.event_name}] INFO:"
  Chef::Log.info("Executing Event #{new_resource.event_name}, with user (#{event_user}), cwd (#{event_cwd}), command (#{new_resource.event_command}), log (#{event_log})")
  # shellout https://github.com/chef/mixlib-shellout
  # switch stderr/stdout with (2>&1 1>&3-), process error (now on stdout), switch back stdout/stderr with (3>&1 1>&2) and then process output
  cmd = Mixlib::ShellOut.new("set -o pipefail; { (#{new_resource.event_command}) 2>&1 1>&3- | ts '#{event_log_prefix_error}' | tee -a #{event_log}; } " \
    "3>&1 1>&2 | ts '#{event_log_prefix_info}' | tee -a #{event_log}", user: event_user, env: event_env, cwd: event_cwd)
  cmd.run_command

  if cmd.error?
    raise "Expected Event #{new_resource.event_name} to exit with #{cmd.valid_exit_codes.inspect}," \
      " but received '#{cmd.exitstatus}', complete log in #{event_log}\n #{format_stderr(cmd)}"
  end
end

action_class do # rubocop:disable Metrics/BlockLength
  def format_stderr(cmd)
    "---- STDERR for #{new_resource.event_name} Event ----\n" \
    "#{cmd.stderr.strip}\n" \
    "---- End STDERR for #{new_resource.event_name} Event ----\n"
  end

  def build_env
    # TODO: move create dir where setting up user/byos/scheduler
    FileUtils.mkdir_p(node['cluster']['byos']['handler_dir'])
    FileUtils.mkdir_p(node['cluster']['byos']['shared_dir'])

    source_cluster_config = node.dig(:cluster, :cluster_config_path)
    raise "Expected cluster configuration file not found in (#{source_cluster_config})" unless ::File.exist?(source_cluster_config)

    target_cluster_config = "#{node['cluster']['byos']['handler_dir']}cluster-config.yaml"
    FileUtils.cp(source_cluster_config, target_cluster_config)

    source_launch_templates = "#{node['cluster']['byos']['shared_dir']}launch_templates.json"
    raise "Expected launch templates file not found in (#{source_launch_templates})" unless ::File.exist?(source_launch_templates)

    target_launch_templates = "#{node['cluster']['byos']['handler_dir']}launch_templates.json"
    FileUtils.cp(source_launch_templates, target_launch_templates) if ::File.exist?(source_launch_templates)

    source_byos_substack_outputs = "#{node['cluster']['byos']['shared_dir']}byos_substack_outputs.json"
    target_byos_substack_outputs = "#{node['cluster']['byos']['handler_dir']}byos_substack_outputs.json"
    byos_substack_arn = node.dig(:cluster, :byos_substack_arn)
    if byos_substack_arn && !byos_substack_arn.empty?
      Chef::Log.info("Found byos substack (#{byos_substack_arn})")
      unless ::File.exist?(source_byos_substack_outputs)
        byos_substack_outputs = { 'Outputs' => {} }
        Chef::Log.info("Executing describe-stack on byos substack (#{byos_substack_arn})")
        retries = 0
        cmd = Mixlib::ShellOut.new("aws cloudformation describe-stacks --region #{node.dig(:ec2, :region)} --stack-name #{byos_substack_arn}", user: 'root')
        begin
          cmd.run_command
          raise if cmd.error?
        rescue StandardError
          if (retries += 1) <= 3
            sleep(retries)
            retry
          end
        end
        raise "Unable to execute describe-stack on byos substack (#{byos_substack_arn})\n #{format_stderr(cmd)}" if cmd.error?

        if cmd.stdout && !cmd.stdout.empty?
          Chef::Log.debug("Output of describe-stacks on substack (#{byos_substack_arn}): (#{cmd.stdout})")
          substack_describe = JSON.parse(cmd.stdout)
          substack_outputs = substack_describe['Stacks'][0]['Outputs']
          substack_outputs.each do |substack_output|
            byos_substack_outputs['Outputs'].merge!({ substack_output['OutputKey'] => substack_output['OutputValue'] })
          end
          ::File.write(source_byos_substack_outputs, byos_substack_outputs.to_json(:only))
        end
      end
      FileUtils.cp(source_byos_substack_outputs, target_byos_substack_outputs)
    end

    source_handler_env = "#{node['cluster']['byos']['shared_dir']}handler_env.json"
    if ::File.exist?(source_handler_env)
      Chef::Log.info("Found handler environment file (#{source_handler_env})")
      env = JSON.load_file(source_handler_env)
      Chef::Log.debug("Loaded handler environment #{env}")
    else
      Chef::Log.info("No handler environment file found, building it")
      env = build_static_env(target_cluster_config, target_launch_templates, target_byos_substack_outputs)

      Chef::Log.info("Dumping handler environment to file (#{source_handler_env})")
      ::File.write(source_handler_env, env.to_json(:only))
    end

    env.merge!(build_dynamic_env)
    env
  end

  def build_dynamic_env
    Chef::Log.info("Building dynamic handler environment")
    env = {}

    # PCLUSTER_EC2_INSTANCE_TYPE
    env.merge!(build_hash_from_node('PCLUSTER_EC2_INSTANCE_TYPE', :ec2, :instance_type))

    case node['cluster']['node_type']
    when 'ComputeFleet'
      # PCLUSTER_QUEUE_NAME
      env.merge!(build_hash_from_node('PCLUSTER_QUEUE_NAME', :cluster, :scheduler_queue_name))

      # PCLUSTER_COMPUTE_RESOURCE_NAME
      env.merge!(build_hash_from_node('PCLUSTER_COMPUTE_RESOURCE_NAME', :cluster, :scheduler_compute_resource_name))
    end

    env
  end

  def build_static_env(target_cluster_config, target_launch_templates, target_byos_substack_outputs)
    Chef::Log.info("Building static handler environment")
    env = {}

    # PCLUSTER_CLUSTER_CONFIG
    env.merge!({ 'PCLUSTER_CLUSTER_CONFIG' => target_cluster_config })

    # PCLUSTER_LAUNCH_TEMPLATES
    env.merge!({ 'PCLUSTER_LAUNCH_TEMPLATES' => target_launch_templates })

    # PCLUSTER_CLUSTER_NAME
    env.merge!(build_hash_from_node('PCLUSTER_CLUSTER_NAME', :cluster, :stack_name))

    # PCLUSTER_CFN_STACK_ARN
    env.merge!(build_hash_from_node('PCLUSTER_CFN_STACK_ARN', :cluster, :stack_arn))

    # PCLUSTER_BYOS_CFN_SUBSTACK_ARN
    env.merge!(build_hash_from_node('PCLUSTER_BYOS_CFN_SUBSTACK_ARN', :cluster, :byos_substack_arn))

    # PCLUSTER_BYOS_CFN_SUBSTACK_OUTPUTS
    env.merge!({ 'PCLUSTER_BYOS_CFN_SUBSTACK_OUTPUTS' => target_byos_substack_outputs }) if ::File.exist?(target_byos_substack_outputs)

    # PCLUSTER_SHARED_SCHEDULER_DIR
    env.merge!(build_hash_from_node('PCLUSTER_SHARED_SCHEDULER_DIR', :byos, :shared_dir))

    # PCLUSTER_LOCAL_SCHEDULER_DIR
    env.merge!(build_hash_from_node('PCLUSTER_LOCAL_SCHEDULER_DIR', :byos, :local_dir))

    # PCLUSTER_AWS_REGION
    env.merge!(build_hash_from_node('PCLUSTER_AWS_REGION', :ec2, :region))

    # PCLUSTER_OS
    env.merge!(build_hash_from_node('PCLUSTER_OS', :cluster, :config, :Image, :Os))

    # PCLUSTER_ARCH
    env.merge!(build_hash_from_node('PCLUSTER_ARCH', :cpu, :architecture))

    # PCLUSTER_VERSION
    env.merge!(build_hash_from_node('PCLUSTER_VERSION', %i[cluster parallelcluster-version]))

    # PCLUSTER_HEADNODE_PRIVATE_IP
    env.merge!(build_hash_from_node('PCLUSTER_HEADNODE_PRIVATE_IP', :ec2, :local_ipv4))

    # PCLUSTER_HEADNODE_HOSTNAME
    env.merge!(build_hash_from_node('PCLUSTER_HEADNODE_HOSTNAME', :ec2, :hostname))

    # PCLUSTER_CLUSTER_CONFIG_OLD
    # TODO: to be implemented

    env
  end

  def build_hash_from_node(name, *path_in_node)
    var = node.dig(*path_in_node)
    var && !var.empty? ? { name => var } : {}
  end
end
