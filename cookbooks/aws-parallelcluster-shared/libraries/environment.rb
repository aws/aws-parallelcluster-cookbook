def aws_region
  node['cluster']['region']
end

def aws_domain
  # Get the aws domain name
  region = aws_region
  if region.start_with?("cn-")
    "amazonaws.com.cn"
  elsif region.start_with?("us-iso-")
    "c2s.ic.gov"
  elsif region.start_with?("us-isob-")
    "sc2s.sgov.gov"
  else
    "amazonaws.com"
  end
end
