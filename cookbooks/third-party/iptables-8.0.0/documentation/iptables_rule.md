[back to resource list](https://github.com/chef-cookbooks/iptables#resources)

---

# iptables_rule

The `iptables_rule` resource can be used to manage configuration of rules for chains using iptables.

More information available at <hhttps://linux.die.net/man/8/iptables>

As this is an accumalator pattern resource not declaring a rule will have it removed

If the property `line` is used all other properties around configuring the iptables rule are ignored

## Actions

`:create`

## Properties

| Name                            | Type        |  Default | Description | Allowed Values |
--------------------------------- | ----------- | -------- | ----------- | -------------- |
| `table`              | `Symbol`       | `:filter` | The table the chain exists on for the rule | `:filter`, `:mangle`, `:nat`, `:raw`, `:security` |
| `chain`         | `Symbol`      | `nil` | The name of the Chain to put this rule on | |
| `ip_version`                  | `Symbol`, `String`      | `:ipv4` | The IP version | `:ipv4`, `:ipv6`, `ipv4`, `ipv6` |
| `protocol`                  | `Symbol`, `String`, `Integer`      | | The protocol to look for | |
| `match`                  | `String`      | | extended packet matching module to use | |
| `source`                  | `String`      | | Source specification. Address can be either a network name, a hostname (please note that specifying any name to be resolved with a remote query such as DNS is a really bad idea), a network IP address (with /mask), or a plain IP address. The mask can be either a network mask or a plain number, specifying the number of 1's at the left side of the network mask. Thus, a mask of 24 is equivalent to 255.255.255.0. A "!" argument before the address specification inverts the sense of the address. | |
| `destination`                  | `String`      | | Destination specification,  Address can be either a network name, a hostname (please note that specifying any name to be resolved with a remote query such as DNS is a really bad idea), a network IP address (with /mask), or a plain IP address. The mask can be either a network mask or a plain number, specifying the number of 1's at the left side of the network mask. Thus, a mask of 24 is equivalent to 255.255.255.0. A "!" argument before the address specification inverts the sense of the address. | |
| `jump`                  | `String`      | | This specifies the target of the rule; i.e., what to do if the packet matches it. The target can be a user-defined chain (other than the one this rule is in), one of the special builtin targets which decide the fate of the packet immediately, or an extension (see EXTENSIONS below). If this option is omitted in a rule (and goto is not used), then matching the rule will have no effect on the packet\'s fate, but the counters on the rule will be incremented. | |
| `go_to`                  | `String`      | | This specifies that the processing should continue in a user specified chain. Unlike the --jump option return will not continue processing in this chain but instead in the chain that called us via jump. | |
| `in_interface`                  | `String`      | | Name of an interface via which a packet was received (only for packets entering the INPUT, FORWARD and PREROUTING chains). When the "!" argument is used before the interface name, the sense is inverted. If the interface name ends in a "+", then any interface which begins with this name will match. If this option is omitted, any interface name will match. | |
| `out_interface`                  | `String`      | | Name of an interface via which a packet is going to be sent (for packets entering the FORWARD, OUTPUT and POSTROUTING chains). When the "!" argument is used before the interface name, the sense is inverted. If the interface name ends in a "+", then any interface which begins with this name will match. If this option is omitted, any interface name will match. | |
| `fragment`                  | `String`      | | Name of an interface via which a packet is going to be sent (for packets entering the FORWARD, OUTPUT and POSTROUTING chains). When the "!" argument is used before the interface name, the sense is inverted. If the interface name ends in a "+", then any interface which begins with this name will match. If this option is omitted, any interface name will match. | |
| `line_number`                  | `Integer`      | | The location to insert the rule into for the chain | greater than 0 |
| `line`                  | `String`      | | Specify the entire line yourself, overrides all other options | |
| `extra_options`                  | `String`      | | Pass in extra arguments which are not available directly, useful with modules | |
| `comment`             | `String` | | A comment to put on the rule | |
| `file_mode`            | `String`     | `0644` | Permissions on the saved output file | |
| `source_template`                       | `source_template`      | `iptables.erb` | Source template to use to create the rules | |
| `cookbook`               | `String`      | `iptables` | Source cookbook to find the template in | |
| `sensitive`               | `true, false`      | `false` | mark the resource as senstive | |
| `config_file`          | `String`     | The default location on disk of the config file, see resource for details | The full path to find the rules on disk | |

## Examples

Allow the interface `lo` always

```ruby
iptables_rule 'Allow from loopback interface' do
  table :filter
  chain :INPUT
  ip_version :ipv4
  jump 'ACCEPT'
  in_interface 'lo'
end
```

Send all trafic to the chain DIVERT

```ruby
iptables_rule 'Divert tcp prerouting' do
  table :mangle
  chain :PREROUTING
  protocol :tcp
  match 'socket'
  ip_version :ipv4
  jump 'DIVERT'
end
```
