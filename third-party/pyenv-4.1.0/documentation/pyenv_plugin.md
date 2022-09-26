# `pyenv_plugin`

Installs a pyenv plugin.

```ruby
pyenv_plugin 'virtualenv' do
  git_url 'https://github.com/pyenv/pyenv-virtualenv'
end
```

| Name        | Type   | Default  | Description                                          |
| ----------- | ------ | -------- | ---------------------------------------------------- |
| git_url     | String |          | Git URL of the plugin                                |
| git_ref     | String | `master` | Git reference of the plugin                          |
| environment | Hash   |          | Optional: pass environment variables to git resource |
| user        | String |          | # Optional: if passed installs to the users pyenv.   |
