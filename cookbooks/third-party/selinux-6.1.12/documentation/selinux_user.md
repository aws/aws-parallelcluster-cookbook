[Back to resource list](../README.md#resources)

# selinux_user

The `selinux_user` resource is used to manage SELinux users on the system.

## Actions

| Action    | Description                                                                             |
| --------- | --------------------------------------------------------------------------------------- |
| `:manage` | *(Default)* Sets the SELinux user to the desired settings regardless of previous state. |
| `:add`    | Creates the SELinux user if not created.(`-a`)                                          |
| `:modify` | Updates the SELinux user if previously created.(`-m`)                                   |
| `:delete` | Removes the SELinux user if previously created. (`-d`)                                  |

## Properties

| Name    | Type   | Default       | Description                                         |
| ------- | ------ | ------------- | --------------------------------------------------- |
| `user`  | String | Resource name | The SELinux user.                                   |
| `level` | String |               | MLS/MCS security level for the user.                |
| `range` | String |               | MLS/MCS security range for the user.                |
| `roles` | Array  |               | SELinux roles for the user (required for creation). |

## Examples

```ruby
# Manage myuser_u SELinux user with a level and range of s0 and roles sysadm_r and staff_r
selinux_user 'myuser_u' do
  level 's0'
  range 's0'
  roles %w(sysadm_r staff_r)
end

# Manage myuser_u SELinux user using the default system level and range and roles sysadm_r and staff_r
selinux_user 'myuser_u' do
  roles %w(sysadm_r staff_r)
end
```
