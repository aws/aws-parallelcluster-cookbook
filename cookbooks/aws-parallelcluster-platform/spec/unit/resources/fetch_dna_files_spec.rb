require 'spec_helper'

class ConvergeFetchDnaFiles
  def self.share(chef_run, extra_chef_attribute_location: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      fetch_dna_files 'share' do
        extra_chef_attribute_location extra_chef_attribute_location
        action :share
      end
    end
  end

  def self.cleanup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      fetch_dna_files 'cleanup' do
        action :cleanup
      end
    end
  end
end

describe 'fetch_dna_files resource' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:script_dir) { 'SCRIPT_DIR' }
      cached(:shared_dir) { 'SHARED_DIR' }
      cached(:region) { 'REGION' }

      context "when we share dna files" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['fetch_dna_files']) do |node|
            node.override['cluster']['scripts_dir'] = script_dir
            node.override['cluster']['shared_dir'] = shared_dir
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['region'] = region
            node.override['kitchen'] = true
          end
          ConvergeFetchDnaFiles.share(runner, extra_chef_attribute_location: "#{kitchen_instance_types_data_path}")
        end
        cached(:node) { chef_run.node }

        # it "it copies data from /tmp/extra.json" do
        #   is_expected.to create_remote_file("copy extra.json")
        #                    .with(path: "#{shared_dir}/dna/extra.json")
        #                    .with(source: "file://#{kitchen_instance_types_data_path}")
        # end

        it 'runs share_compute_fleet_dna.py to get dna files' do
          is_expected.to run_execute('Run share_compute_fleet_dna.py to get user_data.sh and share dna.json with ComputeFleet').with(
            command: "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py" \
              " --region #{node['cluster']['region']}"
          )
        end
      end

      context "when we cleanup dna files" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['fetch_dna_files']) do |node|
            node.override['cluster']['scripts_dir'] = script_dir
            node.override['cluster']['shared_dir'] = shared_dir
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['region'] = region
          end
          allow_any_instance_of(Object).to receive(:aws_domain).and_return(aws_domain)
          ConvergeFetchDnaFiles.cleanup(runner)
        end
        cached(:node) { chef_run.node }

        it 'cleanups dna files' do
          is_expected.to run_execute("Cleanup dna.json and extra.json from #{node['cluster']['shared_dir']}/dna").with(
            command: "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py" \
              " --region #{node['cluster']['region']} --cleanup"
          )
        end
      end
    end
  end
end
