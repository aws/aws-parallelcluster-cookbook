require 'spec_helper'

describe 'get_slurm_accounting_cluster_name' do
  let(:slurm_install_dir) { '/opt/slurm' }
  let(:stack_name) { 'my-stack' }
  let(:node) do
    { 'cluster' => { 'slurm' => { 'install_dir' => slurm_install_dir }, 'stack_name' => stack_name } }
  end
  let(:scontrol_cmd) { "#{slurm_install_dir}/bin/scontrol show config | awk '/^ClusterName/{print $3}'" }

  context 'when ClusterName is not overridden in custom Slurm settings' do
    it 'returns the stack name as fallback' do
      allow_any_instance_of(Object).to receive(:shell_out!).with(scontrol_cmd).and_return(double(stdout: ""))
      expect(get_slurm_accounting_cluster_name).to eq(stack_name)
    end
  end

  context 'when ClusterName is overridden in custom Slurm settings' do
    it 'returns the custom cluster name' do
      allow_any_instance_of(Object).to receive(:shell_out!).with(scontrol_cmd).and_return(double(stdout: "my-custom-cluster\n"))
      expect(get_slurm_accounting_cluster_name).to eq('my-custom-cluster')
    end
  end
end
