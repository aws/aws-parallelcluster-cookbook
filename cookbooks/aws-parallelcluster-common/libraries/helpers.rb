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

def virtualized?
  # Check if we are running in a Docker System Tests
  node.include?('virtualized') and node['virtualized']
end

def redhat8?
  platform?('redhat') && node['platform_version'].to_i == 8
end

def redhat_ubi?
  virtualized? && platform?('redhat')
end

def x86?
  node['kernel']['machine'] == 'x86_64'
end

#
# Check if this is an ARM instance
#
def arm_instance?
  node['kernel']['machine'] == 'aarch64'
end

def get_metadata_token
  # generate the token for retrieving IMDSv2 metadata
  token_uri = URI("http://169.254.169.254/latest/api/token")
  token_request = Net::HTTP::Put.new(token_uri)
  token_request["X-aws-ec2-metadata-token-ttl-seconds"] = "300"
  res = Net::HTTP.new("169.254.169.254").request(token_request)
  res.body
end

def get_metadata_with_token(token, uri)
  # get IMDSv2 metadata with token
  request = Net::HTTP::Get.new(uri)
  request["X-aws-ec2-metadata-token"] = token
  res = Net::HTTP.new("169.254.169.254").request(request)
  metadata = res.body if res.code == '200'
  metadata
end

# Return chrony service reload command
# Chrony doesn't support reload but only force-reload command
def chrony_reload_command
  "systemctl force-reload #{node['cluster']['chrony']['service']}"
end

def format_directory(dir)
  format_dir = dir.strip
  format_dir = "/#{format_dir}" unless format_dir.start_with?('/')
  format_dir
end

#
# Check if GPU acceleration is supported by DCV
#
def dcv_gpu_accel_supported?
  unsupported_gpu_accel_list = ["g5g."]
  !node['ec2']['instance_type'].start_with?(*unsupported_gpu_accel_list)
end

#
# Check if DCV is supported on this OS
#
def platform_supports_dcv?
  node['cluster']['dcv']['supported_os'].include?("#{node['platform']}#{node['platform_version'].to_i}")
end
