[back to resource list](https://github.com/chef-cookbooks/iptables#resources)

---

# iptables_service

The `iptables_service` resource can be used to configure the required service for iptables for autoreloading.

## Actions

`:enable`
`:disable`

## Properties

| Name                            | Type        |  Default | Description | Allowed Values |
--------------------------------- | ----------- | -------- | ----------- | -------------- |
| `ip_version`                  | `Symbol`      | `:ipv4` | The IP version | `:ipv4`, `:ipv6` |
| `sysconfig`   | `Hash` | Correct default settings | A hash of the config settings for sysconfig, see library for more details | |
| `service_name`   | `String` | Correct service name | Name of the iptables services | |
| `sysconfig_file_mode`            | `String`     | `0600` | Permissions on the saved sysconfig file | |

| `file_mode`            | `String`     | `0644` | Permissions on the saved rules file | |
| `source_template`                       | `source_template`      | `iptables.erb` | Source template to use to create the rules | |
| `cookbook`               | `cookbook`      | `iptables` | Source cookbook to find the template in | |
| `sysconfig_file`          | `String`     | The default location on disk of the sysconfig file, see resource for details | The full path to find the sysconfig file on disk | |
| `config_file`          | `String`     | The default location on disk of the config file, see resource for details | The full path to find the rules on disk | |

## Examples

Service configuration for ipv4

```ruby
iptables_service 'iptables services ipv4' do
end
```

service configuration for ipv6

```ruby
iptables_service 'iptables services ipv4' do
  ip_version :ipv6
end

```
