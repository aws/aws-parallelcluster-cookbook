provides :test_resource

unified_mode true

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
    if descriptor.include? "FROM_HOOK"
      # Replace FROM_HOOK keyword with values from the environment
      # Note the value of the property to be replaced must be "FROM_HOOK" even if it's an array.
      # It's up to the post_create script to define an array in the environment.
      # e.g. resource: 'manage_ebs:mount {"shared_dir_array" : ["shared_dir"], "vol_array" : "FROM_HOOK-ebs_mount-vol_array"}'
      Chef::Log.info("FROM_HOOK found in resource properties. Original descriptor is: #{descriptor}")
      properties = Chef::JSONCompat.from_json("{#{descriptor.sub(/.*?{/, '')}")
      properties.each do |key, value|
        Chef::Log.debug("property: #{key}, value: #{value}")
        next unless value.include? "FROM_HOOK"

        env_property = value.sub(/FROM_HOOK-/, '')
        # Retrieve properties from environment file (e.g. values from lifecycle hooks)
        # If an os specific key exists, use it.  Otherwise use an os agnostic key
        # If neither exists log an error
        hook_key_os_specific = "#{env_property}/#{node['cluster']['base_os']}"
        hook_key_os_agnostic = "#{env_property}"
        hook_value_os_specific = node['kitchen_hooks'][hook_key_os_specific]
        hook_value_os_agnostic = node['kitchen_hooks'][hook_key_os_agnostic]
        hook_key = hook_value_os_specific.nil? ? hook_key_os_agnostic : hook_key_os_specific
        hook_value = hook_value_os_specific || hook_value_os_agnostic
        if hook_value.nil?
          Chef::Log.error("Neither an OS specific hook key: #{hook_key_os_specific} nor an OS agnostic hook key:
                           #{hook_key_os_agnostic} was found in the environment. Please define one.")
        else
          Chef::Log.info("Hook key #{hook_key} found in the environment. Replacing FROM_HOOK value with: #{hook_value}")
        end
        properties[key] = hook_value
        Chef::Log.debug("Modified properties are now: #{properties}")
      end
      properties
    else
      Chef::JSONCompat.from_json("{#{descriptor.sub(/.*?{/, '')}")
    end
  else
    {}
  end
end
