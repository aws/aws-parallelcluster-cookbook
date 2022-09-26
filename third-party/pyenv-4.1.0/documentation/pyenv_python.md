# `pyenv_python`

Installs Python.

| Name         | Type            | Default | Description                   |
| ------------ | --------------- | ------- | ----------------------------- |
| version      | `String`        |         | Version of Python to install  |
| version_file | `String`        |         |                               |
| user         | `String`        |         | User to install the Python to |
| environment  | `Hash`          |         |                               |
| verbose      | `[true, false]` | `false` |                               |

## Examples

```ruby
pyenv_python '3.6.1'
```

Install a Python for a user install

```ruby
pyenv_python version do
  user 'vagrant'
end
```
