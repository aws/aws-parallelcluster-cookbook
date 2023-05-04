class OsProperties < Inspec.resource(1)
  name 'os_properties'

  desc '
    Properties of an OS
  '
  example '
    os_properties.redhat_ubi?
  '

  #
  # Check if we are running in a virtualized environment
  #
  def virtualized?
    inspec.virtualization.system == 'docker'
  end

  def redhat_ubi?
    virtualized? && inspec.os.name == 'redhat'
  end

  def redhat?
    inspec.os.name == 'redhat'
  end

  def centos?
    inspec.os.name == 'centos'
  end

  def ubuntu?
    inspec.os.name == 'ubuntu'
  end

  def redhat8?
    redhat? && inspec.os.release.to_i == 8
  end

  def centos7?
    centos? && inspec.os.release.to_i == 7
  end

  def alinux2?
    inspec.os.name == 'amazon' && inspec.os.release.to_i == 2
  end

  def ubuntu1804?
    inspec.os.name == 'ubuntu' && inspec.os.release == '18.04'
  end

  def ubuntu2004?
    inspec.os.name == 'ubuntu' && inspec.os.release == '20.04'
  end

  def debian_family?
    inspec.os.family == 'debian'
  end

  def amazon_family?
    # Inspec family has `amazon` under `linux` family name, but Infra family has
    # a specific `amazon` family, so we need to check this via the os name instead.
    inspec.os.name == 'amazon'
  end

  def arm?
    inspec.os.arch == 'aarch64'
  end

  def x86?
    inspec.os.arch == 'x86_64'
  end
end
