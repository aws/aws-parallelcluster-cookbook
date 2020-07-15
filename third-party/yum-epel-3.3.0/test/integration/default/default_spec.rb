
describe file('/etc/yum.repos.d/epel.repo') do
  it { should exist }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end
