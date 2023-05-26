unified_mode true
default_action :setup

property :aws_region, String

action :add do
  package_repos 'update package repos' do
    action :update
  end

  package_repos 'add nvidia-repo' do
    action :add
    repo_name "nvidia-repo"
    baseurl repository_url
    gpgkey "#{repository_url}/#{repository_key}"
    disable_modularity true
  end
end

action :remove do
  package_repos 'remove nvidia-repo' do
    action :remove
    repo_name "nvidia-repo"
  end
end

def _aws_region
  aws_region || node['cluster']['region']
end

def arch_suffix
  arm_instance? ? 'sbsa' : 'x86_64'
end

def repo_domain
  _aws_region.start_with?('cn-') ? 'cn' : 'com'
end

def repository_url
  "https://developer.download.nvidia.#{repo_domain}/compute/cuda/repos/#{platform}/#{arch_suffix}"
end
