require 'serverspec'

set :backend, :exec
set :path, '/usr/local/bin/:/sbin:/usr/local/sbin:$PATH'

describe file('/opt/sge/bin/lx-amd64/sge_qmaster') do
  it { should be_executable }
end

describe file('/opt/sge/bin/lx-amd64/sge_execd') do
  it { should be_executable }
end

describe file('/opt/sge/bin/lx-amd64/qstat') do
  it { should be_executable }
end
