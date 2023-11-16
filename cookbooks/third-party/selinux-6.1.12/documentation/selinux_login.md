[Back to resource list](../README.md#resources)

# selinux_login

The `selinux_login` resource is used to manage Linux user to SELinux user mappings on the system.

## Actions

| Action    | Description                                                                                      |
| --------- | ------------------------------------------------------------------------------------------------ |
| `:manage` | *(Default)* Sets the SELinux login mapping to the desired settings regardless of previous state. |
| `:add`    | Creates the SELinux login mapping if not created.(`-a`)                                          |
| `:modify` | Updates the SELinux login mapping if previously created.(`-m`)                                   |
| `:delete` | Removes the SELinux login mapping if previously created. (`-d`)                                  |

## Properties

| Name    | Type   | Default       | Description                          |
| ------- | ------ | ------------- | ------------------------------------ |
| `login` | String | Resource name | The OS user login.                   |
| `user`  | String |               | The SELinux user.                    |
| `range` | String |               | MLS/MCS security range for the user. |

## Examples

```ruby
# Manage myuser OS user mapping with a range of s0 and associated SELinux user myuser_u
selinux_login 'myuser' do
  user 'myuser_u'
  range 's0'
end

# Manage myuser OS user mapping using the default system range and associated SELinux user myuser_u
selinux_login 'myuser' do
  user 'myuser_u'
end
```
