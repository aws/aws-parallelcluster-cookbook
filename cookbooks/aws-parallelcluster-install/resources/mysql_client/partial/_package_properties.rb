def package_version
  "8.0.31-1"
end

def package_source_version
  "8.0.31"
end

def package_filename
  "mysql-community-client-#{package_version}.tar.gz"
end

def package_root(s3_url)
  "#{s3_url}/mysql"
end

def package_archive(s3_url)
  "#{package_root(s3_url)}/#{package_platform}/#{package_filename}"
end

def package_source(s3_url)
  "#{s3_url}/source/mysql-#{package_source_version}.tar.gz"
end
