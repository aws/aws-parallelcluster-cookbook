control 'Path' do
  impact 1
  title 'pyenv should be on the path'
  desc 'pyenv bin and shims should be on the path'

  describe bash('source /etc/profile.d/pyenv.sh && echo $PATH') do
    its('stdout') { should match /shims/ }
  end
end

control 'Shims' do
  impact 1
  title 'Pyenv shims should contain the correct Python'
  desc 'When pyen shims is run we should have the correct version of Python shimmed'
  describe bash('source /etc/profile.d/pyenv.sh && pyenv shims') do
    its('stdout') { should match /shims/ }
    its('stdout') { should match /python3.7/ }
  end
end
