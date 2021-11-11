# frozen_string_literal: true

resource_name :alinux_extras_topic
provides :alinux_extras_topic
unified_mode true

# Resource:: to install a package via the Amazon Linux Extras package manager,
# available starting in Amazon Linux 2.

property :topic, String, name_property: true

default_action :install

action :install do
  execute "amazon-linux-extras install -y #{new_resource.topic}" do
    user 'root'
    retries 3
    retry_delay 5
    not_if "amazon-linux-extras | grep #{new_resource.topic} | grep enabled"
  end
end
