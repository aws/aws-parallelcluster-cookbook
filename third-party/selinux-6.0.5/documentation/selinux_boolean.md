[Back to resource list](../README.md#resources)

# selinux_boolean

Set SELinux boolean values.

Introduced: v4.0.0

## Actions

| Action | Description                  |
| ------ | ---------------------------- |
| `:set` | Set the state of the boolean |

## Properties

| Name         | Type                             | Default       | Description                                     |
| ------------ | -------------------------------- | ------------- | ----------------------------------------------- |
| `boolean`    | String                           | Resource name | SELinux boolean to set                          |
| `value`      | `true`, `false`, `'on'`, `'off'` |               | SELinux boolean value                           |
| `persistent` | `true`, `false`                  | `true`        | Set to true for value setting to survive reboot |

## Examples

```ruby
selinux_boolean 'ssh_keysign' do
  value true
end

```

```ruby
selinux_boolean 'staff_exec_content' do
  value false
end
```

```ruby
selinux_boolean 'ssh_sysadm_login' do
  value 'on'
end
```

```ruby
selinux_boolean 'squid_connect_any' do
  value 'off'
end
```
