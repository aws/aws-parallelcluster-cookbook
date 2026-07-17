# frozen_string_literal: true

yum_globalconfig '/etc/yum.conf' do
  action :create
end
