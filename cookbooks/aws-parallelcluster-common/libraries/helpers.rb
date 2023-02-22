#
# Check if we are running in a Docker System Tests
#

class Helpers
  # Putting functions in a class makes them easier to mock

  def self.arm_instance?(node)
    node['kernel']['machine'] == 'aarch64'
  end
end

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

def kernel_release
  ENV['KERNEL_RELEASE'] || node['cluster']['kernel_release']
end

#
# Check if this is an ARM instance
#
def arm_instance?
  Helpers.arm_instance?(node)
end
