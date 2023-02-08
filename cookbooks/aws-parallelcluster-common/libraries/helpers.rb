#
# Check if we are running in a Docker System Tests
#
def virtualized?
  node.include?('virtualized') and node['virtualized']
end

def redhat_ubi?
  virtualized? && platform?('redhat')
end

def x86?
  node['kernel']['machine'] == 'x86_64'
end
