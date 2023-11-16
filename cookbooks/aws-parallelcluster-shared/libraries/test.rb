def on_docker?
  # Check if we are running in a Docker System Tests
  node.include?('virtualized') and node['virtualized']
end

def redhat_on_docker?
  on_docker? && platform?('redhat')
end

def rocky_on_docker?
  on_docker? && platform?('rocky')
end
