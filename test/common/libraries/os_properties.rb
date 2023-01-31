#
# Check if we are running in a virtualized environment
#
class OsProperties < Inspec.resource(1)
  name 'os_properties'

  desc '
    Properties of an OS
  '
  example '
    os_properties.redhat_ubi?
  '

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

  def alinux2?
    inspec.os.name == 'amazon' && inspec.os.release.to_i == 2
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
