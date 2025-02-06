# frozen_string_literal: true

resource_name :fetch_dna_files
provides :fetch_dna_files
unified_mode true

property :extra_chef_attribute_location, String, default: '/tmp/extra.json'

default_action :share

action :share do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  Chef::Log.info("Share extra.json with ComputeFleet")
  ::FileUtils.cp_r(new_resource.extra_chef_attribute_location, "#{node['cluster']['shared_dir']}/dna/extra.json", remove_destination: true) if ::File.exist?(new_resource.extra_chef_attribute_location)

  execute "Share dna.json with ComputeFleet" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/get_compute_user_data.py" \
              " --region #{node['cluster']['region']}"
    timeout 30
    retries 10
    retry_delay 90
  end
end

action :cleanup do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  execute "Cleanup dna.json and extra.json from #{node['cluster']['shared_dir']}/dna" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/get_compute_user_data.py" \
              " --region #{node['cluster']['region']} --cleanup"
    timeout 30
    retries 10
    retry_delay 90
  end
end
