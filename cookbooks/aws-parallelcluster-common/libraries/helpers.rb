#
# Check if we are running in a virtualized environment
#
# FIXME: added virtualized? because this helper does not return true in system-test even if the tests are run in a container
# FIXME: changed the name from docker? to system_test_or_docker?
def system_test_or_docker?
  node['virtualization']['system'] == 'docker' || virtualized?
end

def redhat_ubi?
  system_test_or_docker? && platform?('redhat')
end

def x86?
  node['kernel']['machine'] == 'x86_64'
end
