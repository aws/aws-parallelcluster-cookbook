# pyenv_script

Runs a pyenv aware script.

| Name          | Type                | Default | Description |
| ------------- | ------------------- | ------- | ----------- |
| pyenv_version | `String`            |         |             |
| code          | `String`            |         |             |
| creates       | `String`            |         |             |
| cwd           | `String`            |         |             |
| environment   | `Hash`              |         |             |
| group         | `String`            |         |             |
| path          | `Array`             |         |             |
| returns       | `Array`             | `[0]`   |             |
| timeout       | Integer             |         |             |
| user          | String              |         |             |
| umask         | `[String, Integer]` |         |             |
| live_stream   | `[true, false]`     | `false` |             |

## Examples

```ruby
pyenv_script 'create virtualenv' do
  code "virtualenv #{venv_root}"
  user 'vagrant'
end
```
