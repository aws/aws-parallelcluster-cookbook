# frozen_string_literal: true

resource_name :execute_event_handler
provides :execute_event_handler
unified_mode true

# Resource:: to execute scheduler plugin event handler

property :event_name, String, name_property: true
property :event_command, String, required: false

default_action :run

def raise_and_write_chef_error(raise_message, chef_error = nil)
  unless chef_error
    chef_error = raise_message
  end
  Mixlib::ShellOut.new("echo '#{chef_error}' > /var/log/parallelcluster/bootstrap_error_msg").run_command
  raise raise_message
end

action :run do
  if new_resource.event_command.nil?
    Chef::Log.info("No command defined for Event #{new_resource.event_name}, noop")
    return
  end

  event_log_out = node['cluster']['scheduler_plugin']['handler_log_out']
  event_log_err = node['cluster']['scheduler_plugin']['handler_log_err']
  event_cwd = node['cluster']['scheduler_plugin']['home']
  event_user = node['cluster']['scheduler_plugin']['user']
  event_user_group = node['cluster']['scheduler_plugin']['group']
  event_env = build_env
  event_log_prefix_error = "%Y-%m-%d %H:%M:%S,000 - [#{new_resource.event_name}] - ERROR:"
  event_log_prefix_info = "%Y-%m-%d %H:%M:%S,000 - [#{new_resource.event_name}] - INFO:"
  Chef::Log.info("Executing Event #{new_resource.event_name}, with user (#{event_user}), cwd (#{event_cwd}), command (#{new_resource.event_command}), log out (#{event_log_out}), log err (#{event_log_err})")
  # shellout https://github.com/chef/mixlib-shellout
  # switch stderr/stdout with (2>&1 1>&3-), process error (now on stdout), switch back stdout/stderr with (3>&1 1>&2) and then process output
  event_command = Shellwords.escape("set -o pipefail; { (#{new_resource.event_command}) 2>&1 1>&3- | ts '#{event_log_prefix_error}' | tee -a #{event_log_err}; } " \
    "3>&1 1>&2 | ts '#{event_log_prefix_info}' | tee -a #{event_log_out}")
  cmd = Mixlib::ShellOut.new("/bin/bash -c #{event_command}", user: event_user, group: event_user_group, login: true, env: event_env, cwd: event_cwd)
  cmd.run_command

  if cmd.error?
    raise_message = "Expected Event #{new_resource.event_name} to exit with #{cmd.valid_exit_codes.inspect}," \
      " but received '#{cmd.exitstatus}', complete log info in #{event_log_out} and error in #{event_log_err}\n #{format_stderr(cmd)}"
    chef_error = "Failed when running #{new_resource.event_name} for the configured scheduler plugin." \
      " Additional info can be found in /var/log/chef-client.log, #{event_log_out} and #{event_log_err}."
    raise_and_write_chef_error(raise_message, chef_error)
  end
end

action_class do # rubocop:disable Metrics/BlockLength
  def format_stderr(cmd)
    "---- STDERR for #{new_resource.event_name} Event ----\n" \
    "#{cmd.stderr.strip}\n" \
    "---- End STDERR for #{new_resource.event_name} Event ----\n"
  end

  def build_env
    # copy cluster config
    target_cluster_config = "#{node['cluster']['scheduler_plugin']['handler_dir']}/cluster-config.yaml"
    copy_config("cluster configuration", node.dig(:cluster, :cluster_config_path), target_cluster_config)

    # copy previous cluster config if event is HeadClusterUpdate
    target_previous_cluster_config = "#{node['cluster']['scheduler_plugin']['handler_dir']}/previous-cluster-config.yaml"
    if new_resource.event_name == 'HeadClusterUpdate'
      copy_config("previous cluster configuration", node.dig(:cluster, :previous_cluster_config_path), target_previous_cluster_config)
    end

    # copy computefleet status if event is HeadComputeFleetUpdate
    target_computefleet_status = "#{node['cluster']['scheduler_plugin']['handler_dir']}/computefleet-status.json"
    if new_resource.event_name == 'HeadComputeFleetUpdate'
      copy_config("computefleet status", node.dig(:cluster, :computefleet_status_path), target_computefleet_status)
    end

    # copy launch templates config
    target_launch_templates = "#{node['cluster']['scheduler_plugin']['handler_dir']}/launch-templates-config.json"
    copy_config("launch templates", node.dig(:cluster, :launch_templates_config_path), target_launch_templates)

    # copy instance type data
    target_instance_types_data = "#{node['cluster']['scheduler_plugin']['handler_dir']}/instance-types-data.json"
    copy_config("instance types data", node.dig(:cluster, :instance_types_data_path), target_instance_types_data)

    # generated substack outputs json
    source_scheduler_plugin_substack_outputs = node['cluster']['scheduler_plugin']['scheduler_plugin_substack_outputs_path']
    target_scheduler_plugin_substack_outputs = "#{node['cluster']['scheduler_plugin']['handler_dir']}/scheduler-plugin-substack-outputs.json"
    scheduler_plugin_substack_arn = node.dig(:cluster, :scheduler_plugin_substack_arn)
    if scheduler_plugin_substack_arn && !scheduler_plugin_substack_arn.empty?
      Chef::Log.info("Found scheduler plugin substack (#{scheduler_plugin_substack_arn})")
      if !::File.exist?(source_scheduler_plugin_substack_outputs) || new_resource.event_name == 'HeadClusterUpdate'
        scheduler_plugin_substack_outputs = { 'Outputs' => {} }
        Chef::Log.info("Executing describe-stack on scheduler plugin substack (#{scheduler_plugin_substack_arn})")
        cmd = command_with_retries("aws cloudformation describe-stacks --region #{node.dig(:ec2, :region)} --stack-name #{scheduler_plugin_substack_arn}", 3, 'root', 'root', nil, nil)
        raise "Unable to execute describe-stack on scheduler plugin substack (#{scheduler_plugin_substack_arn})\n #{format_stderr(cmd)}" if cmd.error?

        if cmd.stdout && !cmd.stdout.empty?
          Chef::Log.debug("Output of describe-stacks on substack (#{scheduler_plugin_substack_arn}): (#{cmd.stdout})")
          substack_describe = JSON.parse(cmd.stdout)
          substack_outputs = substack_describe['Stacks'][0]['Outputs']
          if substack_outputs && !substack_outputs.empty?
            substack_outputs.each do |substack_output|
              scheduler_plugin_substack_outputs['Outputs'].merge!({ substack_output['OutputKey'] => substack_output['OutputValue'] })
            end
          end
          ::File.write(source_scheduler_plugin_substack_outputs, scheduler_plugin_substack_outputs.to_json(:only))
        end
      end
    end

    if ::File.exist?(source_scheduler_plugin_substack_outputs)
      copy_config("scheduler plugin substack outputs", source_scheduler_plugin_substack_outputs, target_scheduler_plugin_substack_outputs)
    end

    # Load static env from file or build it if file not found
    source_handler_env = "#{node['cluster']['shared_dir']}/handler-env.json"
    if ::File.exist?(source_handler_env)
      Chef::Log.info("Found handler environment file (#{source_handler_env})")
      env = JSON.load_file(source_handler_env)
      Chef::Log.debug("Loaded handler environment #{env}")
    else
      Chef::Log.info("No handler environment file found, building it")
      env = build_static_env(target_cluster_config, target_launch_templates, target_instance_types_data, target_scheduler_plugin_substack_outputs)

      Chef::Log.info("Dumping handler environment to file (#{source_handler_env})")
      ::File.write(source_handler_env, env.to_json(:only))
    end

    # Merge env with dyanmic env
    env.merge!(build_dynamic_env(target_previous_cluster_config, target_computefleet_status))
    env
  end

  def copy_config(config_type, source_config, target_config)
    raise "Expected #{config_type} file not found in (#{source_config})" unless ::File.exist?(source_config)

    Chef::Log.info("Copying #{config_type} file from (#{source_config}) to (#{target_config})")
    cmd = command_with_retries("cp -f #{source_config} #{target_config}", 0, node['cluster']['scheduler_plugin']['user'], node['cluster']['scheduler_plugin']['group'], nil, nil)
    raise "Unable to copy #{config_type} file from (#{source_config}) to (#{target_config})\n #{format_stderr(cmd)}" if cmd.error?
  end

  def build_dynamic_env(target_previous_cluster_config, target_computefleet_status)
    Chef::Log.info("Building dynamic handler environment")
    env = {}

    if new_resource.event_name == 'HeadClusterUpdate'
      env.merge!({ 'PCLUSTER_CLUSTER_CONFIG_OLD' => target_previous_cluster_config })
    end
    if new_resource.event_name == 'HeadComputeFleetUpdate'
      env.merge!({ 'PCLUSTER_COMPUTEFLEET_STATUS' => target_computefleet_status })
    end
    env.merge!(build_hash_from_node('PCLUSTER_EC2_INSTANCE_TYPE', true, :ec2, :instance_type))

    case node['cluster']['node_type']
    when 'ComputeFleet'
      env.merge!(build_hash_from_node('PCLUSTER_QUEUE_NAME', false, :cluster, :scheduler_queue_name))
      env.merge!(build_hash_from_node('PCLUSTER_COMPUTE_RESOURCE_NAME', false, :cluster, :scheduler_compute_resource_name))
      env.merge!({ 'PCLUSTER_NODE_TYPE' => 'compute' })
    when 'HeadNode'
      env.merge!({ 'PCLUSTER_NODE_TYPE' => 'head' })
    end

    env
  end

  def build_static_env(target_cluster_config, target_launch_templates, target_instance_types_data, target_scheduler_plugin_substack_outputs)
    Chef::Log.info("Building static handler environment")
    env = {}

    env.merge!({ 'PCLUSTER_CLUSTER_CONFIG' => target_cluster_config })
    env.merge!({ 'PCLUSTER_LAUNCH_TEMPLATES' => target_launch_templates })
    env.merge!({ 'PCLUSTER_INSTANCE_TYPES_DATA' => target_instance_types_data })
    env.merge!(build_hash_from_node('PCLUSTER_CLUSTER_NAME', true, :cluster, :stack_name))
    env.merge!(build_hash_from_node('PCLUSTER_CFN_STACK_ARN', true, :cluster, :stack_arn))
    env.merge!(build_hash_from_node('PCLUSTER_SCHEDULER_PLUGIN_CFN_SUBSTACK_ARN', false, :cluster, :scheduler_plugin_substack_arn))
    env.merge!({ 'PCLUSTER_SCHEDULER_PLUGIN_CFN_SUBSTACK_OUTPUTS' => target_scheduler_plugin_substack_outputs }) if ::File.exist?(target_scheduler_plugin_substack_outputs)
    env.merge!(build_hash_from_node('PCLUSTER_SHARED_SCHEDULER_PLUGIN_DIR', true, :cluster, :scheduler_plugin, :shared_dir))
    env.merge!(build_hash_from_node('PCLUSTER_LOCAL_SCHEDULER_PLUGIN_DIR', true, :cluster, :scheduler_plugin, :local_dir))
    env.merge!(build_hash_from_node('PCLUSTER_AWS_REGION', true, :ec2, :region))
    env.merge!(build_hash_from_node('AWS_REGION', true, :ec2, :region))
    env.merge!(build_hash_from_node('PCLUSTER_OS', true, :cluster, :config, :Image, :Os))
    arch = "#{node['cpu']['architecture']}" == 'aarch64' ? 'arm64' : "#{node['cpu']['architecture']}"
    env.merge!({ 'PCLUSTER_ARCH' => arch })
    env.merge!(build_hash_from_node('PCLUSTER_VERSION', true, :cluster, :'parallelcluster-version'))
    env.merge!(build_hash_from_node('PCLUSTER_HEADNODE_PRIVATE_IP', true, :ec2, :local_ipv4))
    env.merge!(build_hash_from_node('PCLUSTER_HEADNODE_HOSTNAME', true, :hostname))
    env.merge!({ 'PCLUSTER_PYTHON_ROOT' => "#{node['cluster']['scheduler_plugin']['virtualenv_path']}/bin" })
    env.merge!({ 'PATH' => "#{node['cluster']['scheduler_plugin']['virtualenv_path']}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/aws/bin:#{node['cluster']['scheduler_plugin']['home']}/.local/bin:#{node['cluster']['scheduler_plugin']['home']}/bin" })
    env.merge!(setup_proxy(:cluster, :proxy))

    env
  end

  def build_hash_from_node(name, raise_if_not_found, *path_in_node)
    var = node.dig(*path_in_node)
    raise "Unable to find node attribute #{path_in_node}" if (!var || var.empty?) && raise_if_not_found

    var && !var.empty? ? { name => var } : {}
  end

  def setup_proxy(*path_in_node)
    var = node.dig(*path_in_node)

    if var && !var.empty? && var != "NONE"
      { 'http_proxy' => var, 'HTTP_PROXY' => var, 'https_proxy' => var, 'HTTPS_PROXY' => var, 'no_proxy' => "localhost,127.0.0.1,169.254.169.254", 'NO_PROXY' => "localhost,127.0.0.1,169.254.169.254" }
    else
      {}
    end
  end

  def command_with_retries(command, retries, user, group, cwd, env)
    retries_count = 0
    cmd = Mixlib::ShellOut.new(command, user: user, group: group, cwd: cwd, env: env)
    begin
      cmd.run_command
      Chef::Log.debug("Failed when executing command (#{command}), with error (#{cmd.stderr.strip}), attempt #{retries_count + 1}/#{retries + 1}")
      raise if cmd.error?
    rescue StandardError
      if (retries_count += 1) <= retries
        sleep(retries_count)
        retry
      end
    end

    cmd
  end
end
