#
# Check if we are running in a Docker System Tests
#
def virtualized?
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
