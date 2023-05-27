def nvidia_enabled?
  ['yes', true].include?(node['cluster']['nvidia']['enabled'])
end

#
# Check if the instance has a GPU
#
def graphic_instance?
  !Mixlib::ShellOut.new("lspci | grep -i -o 'NVIDIA'").run_command.stdout.strip.empty?
end
