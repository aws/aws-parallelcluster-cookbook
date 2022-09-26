# `pyenv_pip`

Used to install a Python package into the selected pyenv environment.

```ruby
pyenv_pip 'requests' do
  virtualenv
  version
  user
  umask
  options
  requirement
  editable
end
```

## Actions

- `:install` - Default. Install a python package. If a version is specified, install the specified version of the python package.
- `:upgrade` - Install/upgrade a python package. Call `install` command with `--upgrade` flag. If version is not specified, latest version will be installed.
- `:uninstall` - Uninstall a python package.

| Name         | Type              | Default        | Description |
| ------------ | ----------------- | -------------- | ----------- |
| package_name | String            | true           |             |
| virtualenv   | String            |                |             |
| version      | String            |                |             |
| user         | String            |                |             |
| umask        | [String, Integer] |                |             |
| options      | String            |                |             |
| requirement  | [true, false]     | false          |             |
| editable     | [true, false]     | default: false |             |
