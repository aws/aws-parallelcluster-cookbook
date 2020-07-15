# The default recipe takes over yum_globalconfig[/etc/yum.conf]
# Test to make sure the package manager still works.

describe command('yum -y install emacs-nox') do
  its('exit_status') { should eq 0 }
end
