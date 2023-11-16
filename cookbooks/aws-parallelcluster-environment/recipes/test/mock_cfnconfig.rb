return if on_docker?

directory '/etc/parallelcluster/'

file '/etc/parallelcluster/cfnconfig' do
  content "cfn_ephemeral_dir=/scratch"
end
