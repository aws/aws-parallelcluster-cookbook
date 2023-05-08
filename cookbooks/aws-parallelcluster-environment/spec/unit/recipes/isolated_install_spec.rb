require 'spec_helper'

describe 'aws-parallelcluster-environment::isolated_install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates scripts directory' do
        is_expected.to create_directory(node['cluster']['scripts_dir']).with_recursive(true)
      end

      it 'creates the template with the correct attributes' do
        is_expected.to create_template("#{node['cluster']['scripts_dir']}/patch-iso-instance.sh").with(
          source: 'isolated/patch-iso-instance.sh.erb',
          owner: 'root',
          group: 'root',
          mode:  '0744',
          variables: {
            users: "root #{node['cluster']['cluster_admin_user']} #{node['cluster']['cluster_user']}",
          }
        )
      end

      it 'has the correct content' do
        is_expected.to render_file("#{node['cluster']['scripts_dir']}/patch-iso-instance.sh")
          .with_content("USERS=(root #{node['cluster']['cluster_admin_user']} #{node['cluster']['cluster_user']})")
      end
    end
  end
end
