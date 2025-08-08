require 'spec_helper'

class ConvergeBlockTopology
  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      block_topology 'configure' do
        action :configure
      end
    end
  end

  def self.update(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      block_topology 'update' do
        action :update
      end
    end
  end
end

script_dir = 'SCRIPT_DIR'
slurm_install_dir = 'SLURM_INSTALL_DIR'
block_sizes = '9,18'
cluster_config = 'CONFIG_YAML'
cookbook_env = 'FAKE_COOKBOOK_PATH'

describe 'block_topology:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::SoloRunner.new(
          platform: platform,
          version: version,
          step_into: ['block_topology']
        ) do |node|
          node.override['cluster']['node_type'] = 'HeadNode'
          node.override['cluster']['scripts_dir'] = script_dir
          node.override['cluster']['slurm']['install_dir'] = slurm_install_dir
          node.override['cluster']['p6egb200_block_sizes'] = block_sizes
          node.override['cluster']['cluster_config_path'] = cluster_config
        end
        allow_any_instance_of(Object).to receive(:is_block_topology_supported).and_return(true)
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_env)
        ConvergeBlockTopology.configure(runner)
        runner
      end

      if platform == 'amazon' && version == '2'
        it 'does not configures block_topology' do
          expect(chef_run).not_to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
          expect(chef_run).not_to run_execute('generate_topology_config')
        end
      else
        it 'creates the topology configuration template' do
          expect(chef_run).to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
            .with(source: 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb')
            .with(user: 'root')
            .with(group: 'root')
            .with(mode: '0644')
        end

        it 'generates topology config when block sizes are present' do
          expect(chef_run).to run_execute('generate_topology_config')
            .with(command: "#{cookbook_env}/bin/python #{script_dir}/slurm/pcluster_topology_generator.py" \
             " --output-file #{slurm_install_dir}/etc/topology.conf" \
             " --block-sizes #{block_sizes}" \
             " --input-file #{cluster_config}")
        end
      end
    end
  end
end

describe 'block_topology:update' do
  for_all_oses do |platform, version|
    ['--cleannup', nil, "--block-sizes #{block_sizes}"].each do |topo_command_args|
      context "on #{platform}#{version}" do
        cached(:chef_run) do
          runner = ChefSpec::SoloRunner.new(
            platform: platform,
            version: version,
            step_into: ['block_topology']
          ) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scripts_dir'] = script_dir
            node.override['cluster']['slurm']['install_dir'] = slurm_install_dir
            node.override['cluster']['p6egb200_block_sizes'] = block_sizes
            node.override['cluster']['cluster_config_path'] = cluster_config
          end
          allow_any_instance_of(Object).to receive(:is_block_topology_supported).and_return(true)
          allow_any_instance_of(Object).to receive(:topology_generator_command_args).and_return(topo_command_args)
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_env)
          ConvergeBlockTopology.update(runner)
          runner
        end

        if platform == 'amazon' && version == '2'
          it 'does not configures block_topology' do
            expect(chef_run).not_to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
            expect(chef_run).not_to run_execute('update or cleanup topology.conf')
          end
        else
          it 'creates the topology configuration template' do
            expect(chef_run).to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
              .with(source: 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0644')
          end

          it 'update or cleanup topology.conf when block sizes are present' do
            expect(chef_run).to run_execute('update or cleanup topology.conf')
              .with(command: "#{cookbook_env}/bin/python #{script_dir}/slurm/pcluster_topology_generator.py" \
               " --output-file #{slurm_install_dir}/etc/topology.conf" \
               " --input-file #{cluster_config}"\
               "#{topo_command_args}")
          end
        end
      end
    end
  end
end

describe 'block_topology:topology_generator_command_args' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['block_topology']) do |node|
          node.override['cluster']['p6egb200_block_sizes'] = nil
        end
      end
      cached(:resource) do
        ConvergeBlockTopology.update(chef_run)
        chef_run.find_resource('block_topology', 'update')
      end

      context "when queues are not updated and topolog.conf does not exists" do
        before do
          allow_any_instance_of(Object).to receive(:are_queues_updated?).and_return(false)
          allow(File).to receive(:exist?).with("#{slurm_install_dir}/etc/topology.conf").and_return(false)
        end

        it 'it gives nil' do
          expect(resource.topology_generator_command_args).to eq(nil)
        end
      end

      context "when block sizes is not nil" do
        before do
          chef_run.node.override['cluster']['p6egb200_block_sizes'] = block_sizes
        end

        it 'returns block-sizes argument' do
          expect(resource.topology_generator_command_args).to eq(" --block-sizes #{block_sizes}")
        end
      end
    end
  end
end
