def aws_domain_for_fsx(region)
  # DNS names have the default AWS domain (amazonaws.com) also in China and GovCloud.
  region.start_with?("us-iso") ? aws_domain : CLASSIC_AWS_DOMAIN
end
