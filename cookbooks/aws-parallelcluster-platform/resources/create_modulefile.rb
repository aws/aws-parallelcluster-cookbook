# frozen_string_literal: true

resource_name :create_modulefile
provides :create_modulefile
unified_mode true

# Modulefiles are used to manage software versions, such as intelmpi versus openmpi
# when a modulefile is loaded, the PATH and sometimes LD_LIBRARY_PATH are changed
# ENV2 is a tool to capture a environment file, such as what comes with intel parallelstudio
# and turn it into an appropriately formatted modulefile.

property :modulefile_dir, String, name_property: true
property :source_path, String, required: true
property :modulefile, String, required: true
property :cookbook, String, default: 'aws-parallelcluster-platform'

default_action :run

action :run do
  directory "#{node['cluster']['scripts_dir']}" do
    recursive true
  end

  # Install env2
  env2 = "#{node['cluster']['scripts_dir']}/env2"
  cookbook_file 'env2' do
    path env2
    mode '0755'
    cookbook new_resource.cookbook
  end

  directory new_resource.modulefile_dir

  # Create modulefile with env2
  modulefile_path = "#{new_resource.modulefile_dir}/#{new_resource.modulefile}"
  bash "create modulefile" do
    code <<-MODULEFILE
      set -e
      echo "#%Module" > #{modulefile_path}
      #{env2} -from bash -to modulecmd #{new_resource.source_path} >> #{modulefile_path}
    MODULEFILE
    creates modulefile_path
  end
end
