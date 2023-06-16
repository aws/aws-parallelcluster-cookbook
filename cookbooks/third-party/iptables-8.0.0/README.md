# iptables Cookbook

[![CI State](https://github.com/chef-cookbooks/iptables/workflows/ci/badge.svg)](https://github.com/chef-cookbooks/iptables/actions?query=workflow%3Aci)
[![Cookbook Version](https://img.shields.io/cookbook/v/iptables.svg)](https://supermarket.chef.io/cookbooks/iptables)

Installs iptables and provides a custom resource for adding and removing iptables rules

## Requirements

### Platforms

- Ubuntu/Debian
- RHEL/CentOS and derivatives
- Amazon Linux

### Chef

- Chef 15.3+

## Resources

- [iptables_packages](https://github.com/chef-cookbooks/iptables/tree/master/documentation/iptables_packages.md)
- [iptables_service](https://github.com/chef-cookbooks/iptables/tree/master/documentation/iptables_service.md)
- [iptables_chain](https://github.com/chef-cookbooks/iptables/tree/master/documentation/iptables_chain.md)
- [iptables_rule](https://github.com/chef-cookbooks/iptables/tree/master/documentation/iptables_rule.md)

## Recipes

### default

The default recipe will install iptables and provides a pair of resources for managing firewall rules for both `iptables` and `ip6tables`.

### disabled

The disabled recipe will install iptables, disable the `iptables` service (on RHEL platforms), and flush the current `iptables` and `ip6tables` rules.

## Attributes

`default['iptables']['iptables_sysconfig']` and `default['iptables']['ip6tables_sysconfig']` are hashes that are used to template /etc/sysconfig/iptables-config and /etc/sysconfig/ip6tables-config. The keys must be upper case and any key / value pair included will be added to the config file.

## License & Authors

**Author:** Cookbook Engineering Team ([cookbooks@chef.io](mailto:cookbooks@chef.io))

**Copyright:** 2008-2020, Chef Software, Inc.

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
