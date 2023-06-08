#
# Retrieve list of macs of network interfaces
#
def network_interface_macs(token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs")
  res = get_metadata_with_token(token, uri)
  res.delete("/").split("\n")
end
