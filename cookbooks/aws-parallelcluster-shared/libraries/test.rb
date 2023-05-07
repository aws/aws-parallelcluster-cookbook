def docker?
  # Check if we are testing in a Docker
  node.include?('virtualized') and node['virtualized']
end

def redhat_ubi?
  docker? && platform?('redhat')
end
