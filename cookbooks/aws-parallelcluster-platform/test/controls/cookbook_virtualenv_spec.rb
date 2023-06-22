control 'tag:install_tag:testami_cookbook_virtualenv_created' do
  python_version = node['cluster']['python-version']
  virtualenv_path = node['cluster']['cookbook_virtualenv_path']
  min_pip_version = '19.3'

  title "cookbook virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat_on_docker? }

  describe directory(virtualenv_path) do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe bash("#{virtualenv_path}/bin/python -V") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /#{python_version}/ }
  end

  describe "pip version should be at least #{min_pip_version}" do
    subject { bash("#{virtualenv_path}/bin/pip -V | awk '{print $2}'") }
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp >= min_pip_version }
  end
end
