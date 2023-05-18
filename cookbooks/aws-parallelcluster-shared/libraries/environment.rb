def aws_region
  node['cluster']['region']
end

def aws_domain
  # Get the aws domain name
  region = aws_region
  if region.start_with?("cn-")
    "amazonaws.com.cn"
  elsif region.start_with?("us-iso-")
    "c2s.ic.gov"
  elsif region.start_with?("us-isob-")
    "sc2s.sgov.gov"
  else
    "amazonaws.com"
  end
end

# Virtual Environments
def virtualenv_path(pyenv_root:, python_version:, virtualenv_name:)
  "#{pyenv_root}/versions/#{python_version}/envs/#{virtualenv_name}"
end

def cookbook_virtualenv_name
  'cookbook_virtualenv'
end

def cookbook_python_version
  node['cluster']['python-version']
end

def cookbook_pyenv_root
  node['cluster']['system_pyenv_root']
end

def cookbook_virtualenv_path
  virtualenv_path(pyenv_root: cookbook_pyenv_root, python_version: cookbook_python_version, virtualenv_name: cookbook_virtualenv_name)
end

def node_virtualenv_name
  'node_virtualenv'
end

def node_python_version
  node['cluster']['python-version']
end

def node_pyenv_root
  node['cluster']['system_pyenv_root']
end

def node_virtualenv_path
  virtualenv_path(pyenv_root: node_pyenv_root, python_version: node_python_version, virtualenv_name: node_virtualenv_name)
end

#
# Check if this is an ARM instance
#
def arm_instance?
  node['kernel']['machine'] == 'aarch64'
end
