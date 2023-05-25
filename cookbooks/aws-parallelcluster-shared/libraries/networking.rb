
# Return the VPC CIDR list from node info
def get_vpc_cidr_list
  if node['ec2']
    mac = node['ec2']['mac']
    vpc_cidr_list = node['ec2']['network_interfaces_macs'][mac]['vpc_ipv4_cidr_blocks']
    vpc_cidr_list.split(/\n+/)
  else
    []
  end
end
