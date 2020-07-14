[back to resource list](https://github.com/chef-cookbooks/iptables#resources)

---

# iptables_packages

The `iptables_packages` resource can be used to install the required packages for iptables.

## Actions

`:install`
`:remove`

## Properties

| Name                            | Type        |  Default | Description | Allowed Values |
--------------------------------- | ----------- | -------- | ----------- | -------------- |
| `package_names`              | `Array`       | Correct packages for platfrom | List of packages required for this cookbook to work | |

## Examples

Install iptables using long form of resource declaration

```ruby
iptables_packages 'install iptables' do
end
```

Install iptables using short form of resource declaration

```ruby
iptables_packages 'install iptables'
```
