def virtualized?
  # Check if we are running in a Docker System Tests
  node.include?('virtualized') and node['virtualized']
end

def format_directory(dir)
  format_dir = dir.strip
  format_dir = "/#{format_dir}" unless format_dir.start_with?('/')
  format_dir
end
