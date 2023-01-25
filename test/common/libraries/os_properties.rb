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

  def docker?
    inspec.virtualization.system == 'docker'
  end

  def redhat_ubi?
    docker? && inspec.os.name == 'redhat'
  end

  def alinux2?
    inspec.os.name == 'amazon' && inspec.os.release.to_i == 2
  end

end
