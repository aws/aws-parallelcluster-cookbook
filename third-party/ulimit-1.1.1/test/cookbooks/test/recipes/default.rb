include_recipe 'ulimit::default'

ulimit_domain 'my_user' do
  rule do
    item :nofile
    type :hard
    value 10000
  end
  rule do
    item :nofile
    type :soft
    value 5000
  end
end

user 'tomcat'

user_ulimit 'tomcat' do
  filehandle_soft_limit 8192
  filehandle_hard_limit 8192
  process_soft_limit 61504
  process_hard_limit 61504
  memory_limit 1024
  core_limit 2048
  core_soft_limit 1024
  core_hard_limit 'unlimited'
  stack_soft_limit 2048
  stack_hard_limit 2048
  rtprio_soft_limit 60
  rtprio_hard_limit 60
end

user_ulimit 'system wide ulimit values' do
  username '*'
  filehandle_soft_limit 8192
  filehandle_hard_limit 8192
  process_soft_limit 61504
  process_hard_limit 61504
  memory_limit 1024
  core_limit 2048
  core_soft_limit 1024
  core_hard_limit 'unlimited'
  stack_soft_limit 2048
  stack_hard_limit 2048
  rtprio_soft_limit 60
  rtprio_hard_limit 60
end
