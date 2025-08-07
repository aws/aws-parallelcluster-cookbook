def nvidia_enabled?
  ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled'])
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

#
# Get Count of GPUs in instance
#
def get_nvswitch_count(device_id)
  shell_out("lspci -d #{device_id} | wc -l").stdout.strip.to_i
end

def get_device_ids
  #  A100 (P4), H100(P5), B200(P6) and GB200()p6e) systems have NVSwitches
  # NVSwitch device id is 10de:1af1 for P4 instance
  # NVSwitch device id is 10de:22a3 for P5 instance
  # NVSwitch device id is 10de:2901 for P6 instance
  # NVSwitch device id is 10de:2941 for P6e instance
  { 'a100' => '10de:1af1', 'h100' => '10de:22a3', 'b200' => '10de:2901', 'gb200' => '10de:2941' }
end
