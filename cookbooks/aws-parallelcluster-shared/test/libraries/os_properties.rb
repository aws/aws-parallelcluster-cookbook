class OsProperties < Inspec.resource(1)
  name 'os_properties'

  desc '
    Properties of an OS
  '
  example '
    os_properties.redhat_on_docker?
  '

  def on_docker?
    inspec.virtualization.system == 'docker'
  end

  def redhat_on_docker?
    on_docker? && inspec.os.name == 'redhat'
  end

  def redhat?
    inspec.os.name == 'redhat'
  end

  def rocky?
    inspec.os.name == 'rocky'
  end

  def rocky_on_docker?
    on_docker? && rocky?
  end

  def ubuntu?
    inspec.os.name == 'ubuntu'
  end

  def ubuntu_on_docker?
    on_docker? && ubuntu?
  end

  def redhat8?
    redhat? && inspec.os.release.to_i == 8
  end

  def redhat9?
    redhat? && inspec.os.release.to_i == 9
  end

  def rocky8?
    rocky? && inspec.os.release.to_i == 8
  end

  def alinux?
    inspec.os.name == 'amazon'
  end

  def alinux2023?
    alinux? && inspec.os.release.to_i == 2023
  end

  def alinux2023_on_docker?
    on_docker? && alinux2023?
  end

  def ubuntu2204?
    inspec.os.name == 'ubuntu' && inspec.os.release == '22.04'
  end

  def ubuntu2404?
    inspec.os.name == 'ubuntu' && inspec.os.release == '24.04'
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
