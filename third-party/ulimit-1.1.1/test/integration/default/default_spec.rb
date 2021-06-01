describe bash('ulimit -a') do
  its('stdout') { should match(/^core file size.*2048$/) }
  its('stdout') { should match(/^max locked memory.*1024$/) }
  its('stdout') { should match(/^open files.*8192$/) }
  its('stdout') { should match(/^stack size.*2048$/) }
  its('stdout') { should match(/^max user processes.*61504$/) }
end
