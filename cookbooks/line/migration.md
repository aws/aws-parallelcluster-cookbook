# Migration

## Removed recipes

The `line::default` recipe has been removed. It was an empty compatibility recipe and is no longer
part of the public cookbook API.

## Use resources directly

Add the specific line-editing resources to your own cookbook recipes.

```ruby
append_if_no_line 'ensure managed line is present' do
  path '/etc/example.conf'
  line 'managed=true'
end
```

```ruby
replace_or_add 'set managed value' do
  path '/etc/example.conf'
  pattern '^managed='
  line 'managed=true'
end
```

## Test cookbook examples

The cookbook's own integration examples now live under `test/cookbooks/test/recipes/`. They show
direct custom resource usage without depending on any recipe from the `line` cookbook.
