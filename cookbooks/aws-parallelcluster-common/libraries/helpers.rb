def virtualized?
  # Check if we are running in a Docker System Tests
  node.include?('virtualized') and node['virtualized']
end

#
# Check if the instance has a GPU
#
def graphic_instance?
  has_gpu = Mixlib::ShellOut.new("lspci | grep -i -o 'NVIDIA'")
  has_gpu.run_command

  !has_gpu.stdout.strip.empty?
end

def format_directory(dir)
  format_dir = dir.strip
  format_dir = "/#{format_dir}" unless format_dir.start_with?('/')
  format_dir
end
