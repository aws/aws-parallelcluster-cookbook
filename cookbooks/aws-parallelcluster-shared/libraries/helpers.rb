class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    strip.empty?
  end
end

#
# Check if a service is installed in the instance and in the specific platform
#
def is_service_installed?(service, platform_families = node['platform_family'])
  if platform_family?(platform_families)
    # Add chkconfig for alinux2 and centos platform, because they do not generate systemd unit file automatically from init script
    # Ubuntu platform generate systemd unit file from init script automatically, if the service is not found by systemd the check will fail because chkconfig does not exist
    shell_out("systemctl daemon-reload; systemctl list-unit-files --all | grep #{service} || chkconfig --list #{service}").exitstatus.to_i.zero?
  else
    # in case of different platform return false
    false
  end
end

#
# Check if Nvidia driver is installed
# TODO: verify if it can be moved to platform cookbook later.
#
def nvidia_installed?
  nvidia_installed = ::File.exist?('/usr/bin/nvidia-smi')
  Chef::Log.warn("Nvidia driver is not installed") unless nvidia_installed
  nvidia_installed
end

#
# Retrieve token to use to retrieve metadata
#
def get_metadata_token
  # generate the token for retrieving IMDSv2 metadata
  token_uri = URI("http://169.254.169.254/latest/api/token")
  token_request = Net::HTTP::Put.new(token_uri)
  token_request["X-aws-ec2-metadata-token-ttl-seconds"] = "300"
  res = Net::HTTP.new("169.254.169.254").request(token_request)
  res.body
end

#
# Retrieve metadata using a given token
#
def get_metadata_with_token(token, uri)
  # get IMDSv2 metadata with token
  request = Net::HTTP::Get.new(uri)
  request["X-aws-ec2-metadata-token"] = token
  res = Net::HTTP.new("169.254.169.254").request(request)
  metadata = res.body if res.code == '200'
  metadata
end

#
# load cluster configuration file into node object
#
def load_cluster_config(config_path)
  ruby_block "load cluster configuration" do
    block do
      require 'yaml'
      Chef::Log.info("Reading Config from #{config_path}")
      config = YAML.safe_load(File.read(config_path))
      Chef::Log.debug("Config read #{config}")
      node.override['cluster']['config'].merge! config
    end
    only_if { node['cluster']['config'].nil? }
  end
end

#
# Check if a custom node package is specified in the config via DevSettings/NodePackage.
#
def is_custom_node?
  custom_node_package = node['cluster']['custom_node_package']
  !custom_node_package.nil? && !custom_node_package.empty?
end

def write_sync_file(path)
  # Write a synchronization file containing the current cluster config version.
  # Synchronization files are used as a synchronization point between cluster nodes
  # to signal that a group of actions have been completed.
  file path do
    content node["cluster"]["cluster_config_version"]
    mode "0644"
    owner "root"
    group "root"
  end
end

def wait_sync_file(path)
  # Wait for a synchronization file to exist.
  # Synchronization files are used as a synchronization point between cluster nodes
  # to signal that a group of actions have been completed.
  # Wait for the config version file to contain the current cluster config version.
  bash "Wait for synchronization file at #{path} to exist" do
    code "[[ -e #{path} ]] || exit 1"
    retries 30
    retry_delay 10
    timeout 5
  end
end

def login_nodes_enabled?
  require 'json'
  lt_config_path = "#{node['cluster']['shared_dir']}/launch-templates-config.json"
  unless ::File.exist?(lt_config_path)
    raise "Unable to determine whether login nodes are enabled: launch templates config file #{lt_config_path} does not exist"
  end

  lt_config = JSON.parse(::File.read(lt_config_path))

  login_pools = lt_config.is_a?(Hash) ? lt_config['LoginPools'] : nil
  login_pools.is_a?(Hash) && !login_pools.empty?
end

def cluster_readiness_check_enabled?
  node['cluster']['cluster_readiness_check_enabled'].to_s.downcase == 'true'
end

def cluster_readiness_check_ignore_failure?
  node['cluster']['cluster_readiness_check_ignore_failure'].to_s.downcase == 'true'
end

# Executes a block with retry logic for handling transient failures.
#
# @param max_retries [Integer] Maximum number of retry attempts (default: 10)
# @param retry_delay [Integer] Seconds to wait between retries (default: 5)
# @param on_retry [Proc] Optional callback executed after each failed attempt (receives attempt number and exception)
# @yield The block to execute with retry protection
# @raise [StandardError] Re-raises the last exception if all retries are exhausted
#
# @example Basic usage
#   with_retries do
#     some_flaky_operation
#   end
#
# @example Advanced usage
#   with_retries(max_retries: 5, retry_delay: 10, on_retry: ->(attempt, e) { cleanup }) do
#     some_flaky_operation
#   end
#
def with_retries(max_retries: 10, retry_delay: 5, on_retry: nil)
  last_exception = nil

  max_retries.times do |attempt|
    begin
      return yield
    rescue StandardError => e
      last_exception = e
      Chef::Log.error("Attempt #{attempt + 1}/#{max_retries} failed: #{e.message}")

      if attempt < max_retries - 1
        if on_retry
          Chef::Log.info("Executing on_retry callback...")
          begin
            on_retry.call(attempt, e)
          rescue StandardError => retry_error
            Chef::Log.error("on_retry callback failed (ignored): #{retry_error.message}")
          end
        end
        Chef::Log.info("Sleeping #{retry_delay}s before next attempt...")
        sleep retry_delay
      end
    end
  end

  Chef::Log.error("All #{max_retries} retry attempts exhausted")
  raise last_exception
end

# Executes a shell command with logging of command, exit status, stdout, and stderr.
#
# @param cmd [String] The shell command to execute
# @param timeout [Integer] Command timeout in seconds (default: nil)
# @param raise_on_error [Boolean] If true, raises exception on non-zero exit (default: false)
# @return [Mixlib::ShellOut] The shell_out result object
#
# @example Basic usage (non-raising)
#   run_cmd('dnf clean metadata')
#
# @example With timeout and raise on error
#   run_cmd('dnf install -y package', timeout: 600, raise_on_error: true)
#
def run_cmd(cmd, timeout: nil, raise_on_error: false)
  Chef::Log.info("Executing: #{cmd}")
  result = raise_on_error ? shell_out!(cmd, timeout: timeout) : shell_out(cmd, timeout: timeout)
  Chef::Log.info("Exit status: #{result.exitstatus}")
  Chef::Log.info("Stdout: #{result.stdout}") unless result.stdout.strip.empty?
  Chef::Log.info("Stderr: #{result.stderr}") unless result.stderr.strip.empty?
  result
end

# Installs RPM packages on RHEL/Rocky with a metadata-refresh + mirror-rotation
# retry strategy that mitigates transient failures caused by out-of-sync RHUI
# mirrors (e.g. "No match for argument: <pkg>-<version>", or rpm transaction
# lock contention with the dnf-makecache timer).
#
# Strategy:
#   1. `dnf install -y --refresh <pkgs>` forces DNF to refresh metadata from
#      the mirror it is currently using.
#   2. `dnf clean metadata` between attempts forces DNF to re-evaluate
#      available mirrors and potentially pick a different one next attempt.
#
# @param packages [Array<String>, String] Package names (optionally version-pinned)
# @param max_retries [Integer] Maximum number of retry attempts (default: 10)
# @param retry_delay [Integer] Seconds to wait between retries (default: 5)
#
# @example
#   dnf_install_with_refresh(%w(dkms rpm-build check check-devel subunit))
#
def dnf_install_with_refresh(packages, max_retries: 10, retry_delay: 5)
  packages = Array(packages)
  Chef::Log.info("Installing packages with mirror refresh retry: #{packages.join(', ')}")

  on_retry = lambda do |_attempt, _exception|
    # This cleanup forces DNF to re-evaluate available mirrors
    # and which mirror to use on the next attempt.
    run_cmd('dnf clean metadata')
  end

  with_retries(
    max_retries: max_retries,
    retry_delay: retry_delay,
    on_retry: on_retry
  ) do
    # --refresh forces DNF to refresh the metadata from the mirror it's currently using.
    run_cmd("dnf install -y --refresh #{packages.join(' ')}", raise_on_error: true)
    Chef::Log.info("Package installation succeeded")
  end
end
