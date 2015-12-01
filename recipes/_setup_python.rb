case node['platform_family']
when 'rhel'
  if node['platform_version'].to_i < 7
    package 'python-pip'
    package 'python-devel'
    bash 'update pip and setuptools' do
      code <<-EOH
        pip install --upgrade pip
        pip install --upgrade setuptools
      EOH
    end
  else
    python_runtime '2' do
      version '2'
      options :system
    end
  end
when 'debian'
  python_runtime '2' do
    version '2'
    options :system
  end
end
