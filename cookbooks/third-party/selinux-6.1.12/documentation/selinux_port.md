[Back to resource list](../README.md#resources)

# selinux_port

Allows assigning a network port to a certain SELinux context, e.g. for running a webserver on a non-standard port.

## Actions

| Action    | Description                                                                     |
| --------- | ------------------------------------------------------------------------------- |
| `:manage` | *(Default)* Assigns the port to the right context regardless of previous state. |
| `:add`    | Assigns the port context if not set.(`-a`)                                      |
| `:modify` | Updates the port context if previously set.(`-m`)                               |
| `:delete` | Removes the port context if set. (`-d`)                                         |

## Properties

| Name        | Type   | Default       | Description                                |
| ----------- | ------ | ------------- | ------------------------------------------ |
| `port`      | String | Resource name | The port in question.                      |
| `protocol`  | String |               | Either `tcp` or `udp`.                     |
| `secontext` | String |               | The SELinux context to assign the port to. |

## Examples

```ruby
# Allow nginx/apache to bind to port 5678 by giving it the http_port_t context
selinux_port '5678' do
 protocol 'tcp'
 secontext 'http_port_t'
end
```
