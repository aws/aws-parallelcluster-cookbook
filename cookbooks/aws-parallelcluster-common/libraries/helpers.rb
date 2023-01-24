#
# Check if we are running in a virtualized environment
#
def virtualized?
  node['virtualization']['system'] == 'docker'
end

def redhat_ubi?
  virtualized? && platform?('redhat')
end
