action :setup do
  # Add MySQL source file
  action_create_source_link

  # An apt update is required to align the apt cache with the current list of available package versions.
  apt_update

  package repository_packages do
    retries 3
    retry_delay 5
  end
end

action_class do
  def repository_packages
    %w(libmysqlclient-dev libmysqlclient21)
  end
end
