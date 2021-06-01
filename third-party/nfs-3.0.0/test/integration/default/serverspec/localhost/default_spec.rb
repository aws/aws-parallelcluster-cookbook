require 'spec_helper'

describe 'Client/Default Tests' do
  include_examples 'services::portmap'
  include_examples 'services::statd'

  if os[:family] == 'redhat' && host_inventory[:platform_version].to_i >= 7
    include_examples 'services::nfs-client'
  end
end
