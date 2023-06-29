def nvidia_enabled?
  ['yes', true].include?(node['cluster']['nvidia']['enabled'])
end

#
# Check if the instance has a GPU
#
def graphic_instance?
  !Mixlib::ShellOut.new("lspci | grep -i -o 'NVIDIA'").run_command.stdout.strip.empty?
end

#
# Check if a process is running
#
def is_process_running(process_name)
  ps = Mixlib::ShellOut.new("ps aux | grep '#{process_name}' | egrep -v \"grep .*#{process_name}\"")
  ps.run_command

  !ps.stdout.strip.empty?
end
