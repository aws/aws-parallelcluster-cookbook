[Back to resource list](../README.md#resources)

# selinux_fcontext

Set the SELinux context of files with `semanage fcontext`.

## Actions

| Action    | Description                                                                     |
| --------- | ------------------------------------------------------------------------------- |
| `:manage` | *(Default)* Assigns the file to the right context regardless of previous state. |
| `:add`    | Assigns the file context if not set.(`-a`)                                      |
| `:modify` | Updates the file context if previously set.(`-m`)                               |
| `:delete` | Removes the file context if set. (`-d`)                                         |

## Properties

| Name        | Type   | Default         | Description                                                                  |
| ----------- | ------ | --------------- | ---------------------------------------------------------------------------- |
| `file_spec` | String | Resource name   | Path or regular expression to files to modify.                               |
| `secontext` | String |                 | The SELinux context to assign the file to.                                   |
| `file_type` | String | `a` (all files) | Restrict the resource to only modifying specific file types. See list below. |

Supported file types:

- **`a`** - All files
- **`f`** - Regular files
- **`d`** - Directory
- **`c`** - Character device
- **`b`** - Block device
- **`s`** - Socket
- **`l`** - Symbolic link
- **`p`** - Named pipe

## Examples

```ruby
# Allow http servers (e.g. nginx/apache) to modify moodle files
selinux_policy_fcontext '/var/www/moodle(/.*)?' do
  secontext 'httpd_sys_rw_content_t'
end

# Adapt a symbolic link
selinux_policy_fcontext '/var/www/symlink_to_webroot' do
  secontext 'httpd_sys_rw_content_t'
  file_type 'l'
end
```
