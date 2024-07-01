# frozen_string_literal: true

provides :install_pyenv
unified_mode true

# Resource:: to create a Python virtual environment for a given user
property :user_only, [true, false], default: false
property :user, String
property :python_version, String
property :prefix, String
default_action :run

action :run do
  python_version = new_resource.python_version || node['cluster']['python-version']
  python_url = "#{node['cluster']['artifacts_build_url']}/python/Python-#{python_version}.tgz"

  if new_resource.user_only
    raise "user property is required for resource install_pyenv when user_only is set to true" unless new_resource.user
    prefix = new_resource.prefix || "#{::File.expand_path("~#{user}")}/.pyenv"
  else
    prefix = new_resource.prefix || node['cluster']['system_pyenv_root']
  end

  directory prefix do
    recursive true
  end

  user = new_resource.user || 'root'

  bash "install python #{python_version}" do
    user user
    group 'root'
    cwd "#{prefix}"
    code <<-VENV
    set -e
    aws s3 cp #{python_url} Python-#{python_version}.tgz --region #{node['cluster']['region']}
    tar -xzf Python-#{python_version}.tgz
    cd Python-#{python_version}
    ./configure --prefix=#{prefix}/versions/#{python_version}
    make
    make install
    VENV
  end
end
