# Install pyenv and makes it avilable to the selected user
version   = '3.6.1'
user      = 'vagrant'
venv_root = "/home/#{user}/venv_test"

cookbook_file '/tmp/requirements.txt' do
  source 'requirements.txt'
  owner user
  group user
  mode '0644'
end

pyenv_user_install user

pyenv_python version do
  user user
end

pyenv_global version do
  user user
end

pyenv_plugin 'virtualenv' do
  git_url 'https://github.com/pyenv/pyenv-virtualenv'
  user    user
end

pyenv_pip 'requests' do
  version '2.18.3'
  user    user
end

pyenv_pip 'virtualenv' do
  version '16.2.0'
end

pyenv_script 'create virtualenv' do
  code "virtualenv #{venv_root}"
  user user
end

pyenv_pip '/tmp/requirements.txt' do
  virtualenv venv_root
  requirement true
end

pyenv_pip 'requests' do
  virtualenv venv_root
  action :uninstall
end
