def on_docker?
  # Check if we are running in a Docker System Tests
  node.include?('virtualized') and node['virtualized']
end

def redhat_on_docker?
  on_docker? && platform?('redhat')
end
