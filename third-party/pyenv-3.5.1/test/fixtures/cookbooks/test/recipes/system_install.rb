# frozen_string_literal: true

version = '3.7.7'
venv_root = '/opt/venv_test'

cookbook_file '/tmp/requirements.txt' do
  source 'requirements.txt'
  mode '0644'
end

# Install pyenv globally
pyenv_system_install 'system'

pyenv_python version

pyenv_global version

pyenv_plugin 'virtualenv' do
  git_url 'https://github.com/pyenv/pyenv-virtualenv'
end

pyenv_pip 'requests' do
  version '2.18.3'
end

pyenv_pip 'virtualenv' do
  version '16.2.0'
end

pyenv_script 'create virtualenv' do
  code "virtualenv #{venv_root}"
end

pyenv_pip '/tmp/requirements.txt' do
  virtualenv venv_root
  requirement true
end

pyenv_pip 'urllib3' do
  virtualenv venv_root
  action :upgrade
  version '1.25.11'
end

pyenv_pip 'requests' do
  virtualenv venv_root
  action :uninstall
end
