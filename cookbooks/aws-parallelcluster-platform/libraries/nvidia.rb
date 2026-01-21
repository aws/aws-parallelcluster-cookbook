# PCI Vendor IDs
NVIDIA_VENDOR_ID = '10de'.freeze
MELLANOX_VENDOR_ID = '15b3'.freeze

# PCI Class IDs
GPU_3D_CONTROLLER_CLASS_ID = '0302'.freeze      # 3D Controllers (GPU without display)
NVSWITCH_BRIDGE_CLASS_ID = '0680'.freeze        # NVSwitch/Bridges
INFINIBAND_CONTROLLER_CLASS_ID = '0207'.freeze  # Infiniband controller (Mellanox CX-7 on P6/B300)

# PCI Device IDs
GB200_DEVICE_ID = '2941'.freeze # P6e (GB200) instance

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
# Get device counts using lspci -d vendor_id:device_id:class_id
#

# Generic function to count PCI devices matching vendor_id:device_id:class_id
# Format: lspci -d [vendor]:[device]:[class]
# Use empty string to match any value for that field
def get_pci_device_count(vendor_id, device_id = '', class_id = '')
  pci_device_filter = "#{vendor_id}:#{device_id}:#{class_id}"
  count = shell_out("lspci -d #{pci_device_filter} | wc -l").stdout.strip.to_i
  Chef::Log.info("PCI device count for filter '#{pci_device_filter}': #{count}")
  count
end

# Count NVIDIA GPUs (3D controllers)
def get_gpu_count
  get_pci_device_count(NVIDIA_VENDOR_ID, '', GPU_3D_CONTROLLER_CLASS_ID)
end

# Count NVIDIA NVSwitches (Bridges)
def get_nvswitch_count
  get_pci_device_count(NVIDIA_VENDOR_ID, '', NVSWITCH_BRIDGE_CLASS_ID)
end

# Count Mellanox Infiniband controllers (CX-7 bridges on P6/B300)
def get_mellanox_bridge_count
  get_pci_device_count(MELLANOX_VENDOR_ID, '', INFINIBAND_CONTROLLER_CLASS_ID)
end

# Count GB200 devices by specific device ID
def get_gb200_count
  get_pci_device_count(NVIDIA_VENDOR_ID, GB200_DEVICE_ID)
end

def enable_fabric_manager?
  return false if get_gpu_count <= 1

  # Enable if NVSwitch bridges or Mellanox Infiniband controllers are detected
  (get_nvswitch_count > 1) || (get_mellanox_bridge_count > 1)
end

def is_gb200_node?
  get_gb200_count > 1
end
