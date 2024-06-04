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

def alinux2023_on_docker?
  on_docker? && platform?('amazon') && node['platform_version'].to_i == 2023
end
