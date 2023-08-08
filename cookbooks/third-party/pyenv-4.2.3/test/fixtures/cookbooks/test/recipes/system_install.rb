# Install Python system wide
# and make it the global default

version = '3.7.7'
local_folder = '/opt/pyenv_test'

directory local_folder

pyenv_install 'system'

# pyenv_rehash 'for-new-python'

pyenv_python version

pyenv_local version do
  path local_folder
  user 'root'
end

pyenv_global version

pyenv_plugin 'virtualenv' do
  git_url 'https://github.com/pyenv/pyenv-virtualenv'
end

pyenv_pip 'requests' do
  version '2.18.3'
end
