# This service is loaded lazily and wait until a connection is attempted to
# start so, manually start them here so that Kitchen can test for them

service 'rpcbind' do
  action [:enable, :start]
end
