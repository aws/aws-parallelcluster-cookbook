require 'spec_helper'

describe 'Server Tests' do
  include_examples 'services::portmap'
  include_examples 'services::statd'
  include_examples 'services::mountd'
  include_examples 'services::lockd'

  if os[:family] == 'redhat'
    include_examples 'services::nfs-client' if host_inventory[:platform_version].to_f >= 7.1
    include_examples 'services::nfs-server'
  end

  include_examples 'issues::server'
end
