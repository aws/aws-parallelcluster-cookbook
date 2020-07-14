# git repository containing pyenv
default['pyenv']['git_url'] = 'https://github.com/pyenv/pyenv.git'
default['pyenv']['git_ref'] = 'master'

default['pyenv']['prerequisites'] = case node['platform_family']
                                    when 'debian'
                                      %w(make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git)
                                    when 'rhel', 'fedora', 'amazon' # oracle, centos, amazon, fedora
                                      %w(git zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel findutils)
                                    when 'suse'
                                      %w(git git-core zlib-devel bzip2 libbz2-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel)
                                    when 'mac_os_x'
                                      %w(git readline xz) # not tested
                                    end
