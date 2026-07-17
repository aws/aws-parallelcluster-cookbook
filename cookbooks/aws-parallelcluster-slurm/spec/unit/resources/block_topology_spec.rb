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
new_block_size = '1,2'
cluster_config = 'CONFIG_YAML'
cookbook_env = 'FAKE_COOKBOOK_PATH'
force_configuration_extra_args = ' --force-configuration'

describe 'block_topology:configure' do
  ['false', false, 'no', 'true', true, 'yes'].each do |force_configuration|
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
            node.override['cluster']['slurm']['block_topology']['force_configuration'] = force_configuration
          end
          allow_any_instance_of(Object).to receive(:is_block_topology_supported).and_return(true)
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_env)
          ConvergeBlockTopology.configure(runner)
          runner
        end

        it 'creates the topology configuration template' do
          expect(chef_run).to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
            .with(source: 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb')
            .with(user: 'root')
            .with(group: 'root')
            .with(mode: '0644')
        end
        command = "#{cookbook_env}/bin/python #{script_dir}/slurm/pcluster_topology_generator.py" \
          " --output-file #{slurm_install_dir}/etc/topology.conf" \
          " --block-sizes #{block_sizes}" \
          " --input-file #{cluster_config}"
        command_to_exe = if ['true', 'yes', true].include?(force_configuration)
                           "#{command}#{force_configuration_extra_args}"
                         else
                           "#{command}"
                         end
        it 'generates topology config when block sizes are present' do
          expect(chef_run).to run_execute('generate_topology_config')
            .with(command: command_to_exe)
        end
      end
    end
  end
end

describe 'block_topology:update' do
  ['false', false, 'no', 'true', true, 'yes'].each do |force_configuration|
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
              node.override['cluster']['slurm']['block_topology']['force_configuration'] = force_configuration
            end
            allow_any_instance_of(Object).to receive(:is_block_topology_supported).and_return(true)
            allow_any_instance_of(Object).to receive(:topology_generator_command_args).and_return(topo_command_args)
            allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_env)
            ConvergeBlockTopology.update(runner)
            runner
          end

          command = "#{cookbook_env}/bin/python #{script_dir}/slurm/pcluster_topology_generator.py" \
            " --output-file #{slurm_install_dir}/etc/topology.conf" \
            " --input-file #{cluster_config}"\
            "#{topo_command_args}"
          command_to_exe = if ['true', 'yes', true].include?(force_configuration)
                             "#{command}#{force_configuration_extra_args}"
                           else
                             "#{command}"
                           end

          it 'creates the topology configuration template' do
            expect(chef_run).to create_template("#{slurm_install_dir}/etc/slurm_parallelcluster_topology.conf")
              .with(source: 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb')
              .with(user: 'root')
              .with(group: 'root')
              .with(mode: '0644')
          end

          if topo_command_args.nil?
            it 'update or cleanup topology.conf when block sizes are present' do
              expect(chef_run).not_to run_execute('update or cleanup topology.conf')
                .with(command: command_to_exe)
            end
          else
            it 'update or cleanup topology.conf when block sizes are present' do
              expect(chef_run).to run_execute('update or cleanup topology.conf')
                .with(command: command_to_exe)
            end
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
          node.override['cluster']['slurm']['install_dir'] = slurm_install_dir
        end
      end
      cached(:resource) do
        ConvergeBlockTopology.update(chef_run)
        chef_run.find_resource('block_topology', 'update')
      end

      context "when capacity block is removed and topolog.conf does exists" do
        before do
          allow(File).to receive(:exist?).with("#{slurm_install_dir}/etc/topology.conf").and_return(true)
          chef_run.node.override['cluster']['p6egb200_block_sizes'] = nil
        end

        it 'returns cleanup' do
          expect(resource.topology_generator_command_args).to eq(" --cleanup")
        end
      end

      context "when capacity block is not used and topolog.conf does not exists" do
        before do
          allow(File).to receive(:exist?).with("#{slurm_install_dir}/etc/topology.conf").and_return(false)
          chef_run.node.override['cluster']['p6egb200_block_sizes'] = nil
        end

        it 'it gives nil' do
          expect(resource.topology_generator_command_args).to eq(nil)
        end
      end

      context "when capacity block is updated and topolog.conf does not exists" do
        before do
          allow(File).to receive(:exist?).with("#{slurm_install_dir}/etc/topology.conf").and_return(false)
          chef_run.node.override['cluster']['p6egb200_block_sizes'] = block_sizes
        end

        it 'returns block-sizes argument' do
          expect(resource.topology_generator_command_args).to eq(" --block-sizes #{block_sizes}")
        end
      end

      context "when capacity block is updated and topolog.conf does exists" do
        before do
          allow(File).to receive(:exist?).with("#{slurm_install_dir}/etc/topology.conf").and_return(true)
          chef_run.node.override['cluster']['p6egb200_block_sizes'] = new_block_size
        end

        it 'returns block-sizes argument' do
          expect(resource.topology_generator_command_args).to eq(" --block-sizes #{new_block_size}")
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
