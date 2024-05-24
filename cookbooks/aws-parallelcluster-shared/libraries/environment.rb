def aws_region
  node['cluster']['region']
end

CLASSIC_AWS_DOMAIN = "amazonaws.com".freeze
CHINA_AWS_DOMAIN = "amazonaws.com.cn".freeze
US_ISO_AWS_DOMAIN = "c2s.ic.gov".freeze
US_ISOB_AWS_DOMAIN = "sc2s.sgov.gov".freeze

def aws_domain
  # Get the aws domain name
  region = aws_region
  if region.start_with?("cn-")
    CHINA_AWS_DOMAIN
  elsif region.start_with?("us-iso-")
    US_ISO_AWS_DOMAIN
  elsif region.start_with?("us-isob-")
    US_ISOB_AWS_DOMAIN
  else
    CLASSIC_AWS_DOMAIN
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

def x86_instance?
  node['kernel']['machine'] == 'x86_64'
end

#
# Check if DCV is installed
#
def dcv_installed?
  ::File.exist?("/etc/dcv/dcv.conf")
end
