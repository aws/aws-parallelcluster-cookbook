# `pyenv_install`

Installs pyenv to either a user or system location.

Install PyEnv under the vagrant home directory

```ruby
pyenv_install 'user' do
  user 'vagrant'
end
```

Install PyEnv globally

```ruby
pyenv_install 'system'
```

| Name         | Type            | Allowed Options                            | Default                              | Description                                            |
| ------------ | --------------- | ------------------------------------------ | ------------------------------------ | ------------------------------------------------------ |
| prefix_type  | String          | user system                                |                                      | Whether to install pyenv to a user or system directory |
| user         | String          |                                            | `root`                               | User directory to install pyenv to                     |
| group        | String,         |                                            | `user`                               | Group for the pyenv directories and files              |
| git_url      | String          |                                            | `https://github.com/pyenv/pyenv.git` |                                                        |
| git_ref      | String,         |                                            |                                      | `master`                                               |
| home_dir     | String          |                                            | user home                            |                                                        |
| prefix       | String          | `/usr/local/pyenv` or users home directory | Path to install pyenv to             |                                                        |
| environment  | Hash            |                                            |                                      |                                                        |
| update_pyenv | `true`, `false` |                                            | false                                |                                                        |
