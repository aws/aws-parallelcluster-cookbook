# frozen_string_literal: true

provides :chrony
unified_mode true

action :setup do
  return if redhat_on_docker?

  package_repos 'update package repositories' do
    action :update
  end

  # Install Amazon Time Sync
  package %w(ntp ntpdate ntp*) do
    action :remove
  end

  package %w(chrony) do
    retries 3
    retry_delay 5
  end

  append_if_no_line "add configuration to chrony.conf" do
    path chrony_conf_path
    line "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4"
    notifies :stop, "service[#{chrony_service}]", :immediately
    notifies :reload, "service[#{chrony_service}]", :delayed
  end

  service chrony_service do
    reload_command chrony_reload_command
    action :nothing
  end
end

action :enable do
  service chrony_service do
    # chrony service supports restart but is not correctly checking if the process is stopped before starting the new one
    supports restart: false
    reload_command chrony_reload_command
    action %i(enable start)
    retries 5
    retry_delay 10
  end unless redhat_on_docker?
end

action_class do
  def chrony_reload_command
    "systemctl force-reload #{chrony_service}"
  end
end
