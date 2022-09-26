# `pyenv_rehash`

Rehashes the system or user pyenv.

| Name | Type     | Default | Description    |
| ---- | -------- | ------- | -------------- |
| user | `String` |         | User to rehash |

## Examples

```ruby
pyenv_rehash 'rehash' do
  user 'vagrant'
end
```

```ruby
pyenv 'rehash'
```
