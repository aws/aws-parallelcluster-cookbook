# `pyenv_global`

If a user is passed in to this resource it sets the global version for the user, under the users root_path (usually `~/.pyenv/version`), otherwise it sets the system global version.

| Name          | Type   | Default   | Description |
| ------------- | ------ | --------- | ----------- |
| pyenv_version | String |           |             |
| user          | String |           |             |
| prefix        | String | root_path |             |

## Examples

```ruby
pyenv_global '3.6.1'
```
