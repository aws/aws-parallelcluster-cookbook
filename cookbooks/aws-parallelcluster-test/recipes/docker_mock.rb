return unless virtualized?

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
esac
}
end

file '/sbin/chkconfig' do
  content %(
#!/bin/bash
echo "service         0:off   1:off   2:on    3:on    4:on    5:on    6:off"
)
end

%w(
  /etc/init.d/rpc-statd
  /etc/init.d/rpc-statd.service
  /etc/init.d/nfs-idmapd
  /etc/init.d/nfs-client.target
  /etc/init.d/nfs-config.service
  /etc/init.d/nfs-kernel-server.service
  /usr/local/bin/udevadm
  /usr/local/sbin/sysctl
  /usr/local/sbin/modprobe).each do |mock|
  file mock do
    content '#\! /usr/bin/bash'
    mode '0744'
  end
end

directory '/sbin/service' do
  mode '0777'
end
directory '/etc/cron.daily'
directory '/etc/cron.weekly'
