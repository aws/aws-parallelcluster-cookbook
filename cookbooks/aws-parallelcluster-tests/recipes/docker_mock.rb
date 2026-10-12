return unless on_docker?

file '/bin/systemctl' do
  content %{
#!/bin/bash

if [ "$1" == "--system" ]; then
    shift
fi

action=$1
service=$2

case $action in
    show)
    echo -e "StatusErrno=0\nExecMainStatus=0\nLoadState=loaded\nActiveState=active\nSubState=active\nUnitFileState=enabled\n"
    ;;
    start)
    ;;
    restart)
    ;;
esac
}
end

file '/sbin/chkconfig' do
  content %(
#!/bin/bash
echo "service         0:off   1:off   2:on    3:on    4:on    5:on    6:off"
)
  mode '0744'
end

%w(
  /sbin/service
  /usr/local/bin/udevadm
  /usr/local/sbin/sysctl
  /usr/local/sbin/modprobe).each do |mock|
  file mock do
    content '#\! /usr/bin/bash'
    mode '0744'
  end
end

directory '/etc/cron.daily'
directory '/etc/cron.weekly'

directory '/etc/chef'
directory '/etc/parallelcluster'

if platform_family?('debian')
  %w(nfs-common nfs-kernel-server).each do |nfspkg|
    package nfspkg
  end
elsif !redhat_on_docker?
  #  Rhel family except redhat
  package 'nfs-utils'
end

if redhat_on_docker?
  package 'openssh-clients'
  package 'python3'
  package 'python3-pip'

  # Mock python environment
  package 'python39'
  link '/usr/bin/python' do
    to '/usr/bin/python3.9'
  end

  bash 'Install requirements' do
    cwd Chef::Config[:file_cache_path]
    code "/usr/bin/python -m pip install -r cookbooks/aws-parallelcluster-platform/files/cookbook_virtualenv/requirements.txt"
  end
end

if alinux2023_on_docker?
  # Create pcluster-admin user and group
  group 'pcluster-admin' do
    gid 400
  end

  user 'pcluster-admin' do
    uid 400
    gid 400
    home '/home/pcluster-admin'
    shell '/bin/bash'
  end

  # Create required directories
  directory '/opt/parallelcluster/shared' do
    recursive true
  end

  # Install Python 3.12 for AL2023 Docker tests
  package 'python3.12'
  package 'python3.12-pip'

  # Mock python environment for AL2023 Docker tests
  # The pyenv/virtualenv setup doesn't work in Docker because it requires S3 access
  python_version = node['cluster']['python-version']
  pyenv_root = node['cluster']['system_pyenv_root']
  virtualenv_path = "#{pyenv_root}/versions/#{python_version}/envs/cookbook_virtualenv"

  directory "#{virtualenv_path}/bin" do
    recursive true
  end

  # Create a wrapper script that reports the expected version but uses system Python
  file "#{virtualenv_path}/bin/python" do
    content %(#!/bin/bash
if [[ "$1" == "-V" || "$1" == "--version" ]]; then
  echo "Python #{python_version}"
else
  exec /usr/bin/python3.12 "$@"
fi
)
    mode '0755'
  end

  link "#{virtualenv_path}/bin/pip" do
    to '/usr/bin/pip3.12'
  end

  bash 'Install cookbook requirements for AL2023' do
    cwd Chef::Config[:file_cache_path]
    code "/usr/bin/python3.12 -m pip install -r cookbooks/aws-parallelcluster-platform/files/cookbook_virtualenv/requirements.txt"
  end
end

file '/usr/bin/ssh-keyscan' do
  content %(
    #!/bin/bash
    exit 0
    )
  mode '0755'
end
