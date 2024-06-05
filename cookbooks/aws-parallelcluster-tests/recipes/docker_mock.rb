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

file '/usr/bin/ssh-keyscan' do
  content %(
    #!/bin/bash
    exit 0
    )
  mode '0755'
end
