def aws_domain_for_fsx(region)
  # DNS names have the default AWS domain (amazonaws.com) also in China and GovCloud.
  if region.start_with?("us-iso-")
    US_ISO_AWS_DOMAIN
  elsif region.start_with?("us-isob-")
    US_ISOB_AWS_DOMAIN
  else
    CLASSIC_AWS_DOMAIN
  end
end
