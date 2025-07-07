# Upgrading

This document will give you help on upgrading major versions of iptables

## 8.0.0

### Added

- Resource `iptables_chain`
  - Property `value` which is used to define the default value of the chain, it defaults to `' ACCEPT [0:0]'`
  - Property `ip_version` which is used to allow this resource to handle both `:ipv4` and `:ipv6`

- Resource `iptables_rule`
  - Property `ip_version` which is used to allow this resource to handle both `:ipv4` and `:ipv6`
  - Property `protocol` which allows you to define the protocol the rule should match against
  - Property `source` which allows you to define the source specification
  - Property `destination` which allows you to define the destination specification
  - Property `jump` which allows you to specify the action to take on a matching packet
  - Property `go_to` which allows you to specify that the processing should take place in a different chain
  - Property `in_interface` which is the name of the interfact to match against, e.g.: `lo`
  - Property `out_interface` which is the name of the interface the packet is going to be sent from
  - Property `line_number` which is where gives you the ability to place a rule at a certian location

- Resource `iptables_packages` to install iptables

### Removed

- Resource `iptables_chain`
  - Property `chain` no longer supports `Hash` or `Array` values
- Resource `iptables_chain6` has been marked as deprecated and will be removed in the next version, use `iptables_chain` with property `ip_version` set to `:ipv6`
- Resource `iptables_rule6` has been marked as deprecated and will be removed in the next version, use `iptables_rule` with property `ip_version` set to `:ipv6`
- Attributes
  - `['iptables']['persisted_rules_template']` if you still wish to use these it is recommended you loop through them to call the `iptables_chain` and `iptables_rule` resources
  - `['iptables']['persisted_rules_iptables']` has been replaced with a helper library and the ability to override it on the resources using the `source_template` resource

### Changed

- Resource `iptables_chain`
  - Property `source` has been renamed to `source_template`
  - Property `table` now expects a `Symbol` and will warn if a String is passed in
  - Property `chain` now accepts a `String` only
- Resource `iptables_table`
  - Property `source` has been renamed to `source_template`
  - Property `table` now expects a `Symbol` and will warn if a String is passed in
  - Property `chain` now expects a `Symbol` and will warn if a String is passed in
  - Property `match` now prefixes the `String` passed in with `-m` so you only need to pass in the match provider name, e.g: `tcp`
  - Property `target` has been deprecated please use property `jump`
- Recipe `iptables::default` now gets it's iptables config file path from a helper library
