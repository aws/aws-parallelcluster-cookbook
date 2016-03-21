require 'serverspec'

set :backend, :exec
set :path, '/usr/local/bin/:/sbin:/usr/local/sbin:$PATH'

describe command('pip --version') do
  its(:exit_status) { should eq 0 }
end

describe command('aws --version') do
  its(:exit_status) { should eq 0 }
end

describe command('getenforce') do
  its(:stdout) { should match(/Permissive|Disabled/) }
end
