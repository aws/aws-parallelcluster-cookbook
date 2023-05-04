[Back to resource list](../README.md#resources)

# selinux_state

The `selinux_state` resource is used to manage the SELinux state on the system. It does this by using the `setenforce` command and rendering the `/etc/selinux/config` file from a template.

Introduced: v4.0.0

## Actions

| Action        | Description                                    |
| ------------- | ---------------------------------------------- |
| `:enforcing`  | *(Default)* Set the SELinux state to enforcing |
| `:permissive` | Set the state to permissive                    |
| `:disabled`   | Set the state to disabled                      |
`
> ⚠ Switching to or from `disabled` requires a reboot!

## Properties

| Name               | Type                | Default               | Description                                                        |
| ------------------ | ------------------- | --------------------- | ------------------------------------------------------------------ |
| `config_file`      | String              | `/etc/selinux/config` | Path to SELinux config file on disk                                |
| `persistent`       | true, false         | `true`                | Persist status update to the selinux configuration file            |
| `policy`           | String              | `targeted`            | SELinux policy type                                                |
| `automatic_reboot` | true, false, Symbol | `false`               | Whether to automatically reboot the node if needed to change state |

## Examples

```ruby
selinux_state 'enforcing' do
  action :enforcing
end
```

```ruby
selinux_state 'permissive' do
  action :permissive
end
```

```ruby
selinux_state 'disabled' do
  action :disabled
end
```

## Usage

### Managing SELinux State (`selinux_state`)

Simply set SELinux to enforcing or permissive:

```ruby
selinux_state "SELinux Enforcing" do
  action :enforcing
end

selinux_state "SELinux Permissive" do
  action :permissive
end
```

The action here is based on the value of the `node['selinux']['state']` attribute, which we convert to lower-case and make a symbol to pass to the action.

```ruby
selinux_state "SELinux #{node['selinux']['state'].capitalize}" do
  action node['selinux']['state'].downcase.to_sym
end
```

The action here is based on the value of the `node['selinux']['status']` attribute, which we convert to lower-case and make a symbol to pass to the action.

```ruby
selinux_state "SELinux #{node['selinux']['status'].capitalize}" do
  action node['selinux']['status'].downcase.to_sym
end
```
