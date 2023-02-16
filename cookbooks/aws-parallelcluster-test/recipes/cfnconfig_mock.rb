return if virtualized?

directory '/etc/parallelcluster/'

file '/etc/parallelcluster/cfnconfig' do
  content "cfn_ephemeral_dir=/scratch"
end
