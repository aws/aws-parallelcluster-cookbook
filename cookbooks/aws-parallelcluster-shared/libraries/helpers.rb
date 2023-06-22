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
def load_cluster_config
  ruby_block "load cluster configuration" do
    block do
      require 'yaml'
      config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
      Chef::Log.debug("Config read #{config}")
      node.override['cluster']['config'].merge! config
    end
    only_if { node['cluster']['config'].nil? }
  end
end

#
# Check if custom node is specified in the config
#
def is_custom_node?
  custom_node_package = node['cluster']['custom_node_package']
  !custom_node_package.nil? && !custom_node_package.empty?
end
