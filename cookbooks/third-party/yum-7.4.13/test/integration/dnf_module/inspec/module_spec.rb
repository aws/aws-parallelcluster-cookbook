describe command('dnf module list') do
  its('stdout') { should match /nodejs +12 \[e\]/ }
  its('stdout') { should match /ruby +2.7 \[e\]/ }
  its('stdout') { should match /php +remi-8.1 \[e\]/ }
  its('stdout') { should match /mysql.+\[x\]/ }
end

describe command('node --version') do
  its('stdout') { should match /v12/ }
end

describe command('ruby --version') do
  its('stdout') { should match /ruby 2.7/ }
end

describe command('php --version') do
  its('stdout') { should match /PHP 8.1/ }
end
