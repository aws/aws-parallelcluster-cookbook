provides :test_resource

property :descriptor, String

action :use do
  declare_resource(its_name, 'test') do
    properties = its_properties
    properties.each_key do |key|
      send("#{key}=", properties[key])
    end
    action its_action
  end
end

def its_name
  descriptor.sub(/{.*/, '').strip.split(/:/)[0]
end

def its_action
  descriptor.sub(/{.*/, '').strip.split(/:/)[1]
end

def its_properties
  if descriptor.include? "{"
    Chef::JSONCompat.from_json("{#{descriptor.sub(/.*?{/, '')}")
  else
    {}
  end
end
