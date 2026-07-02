# Resource: replace_or_add

## Actions

| Action | Description                                                                                     |
|--------|-------------------------------------------------------------------------------------------------|
| edit   | Replace lines that match the pattern. Append the line unless a source line matches the pattern. |

## Properties

| Properties            | Description                                                                                               | Type                         | Values and Default                      |
|-----------------------|-----------------------------------------------------------------------------------------------------------|------------------------------|-----------------------------------------|
| path                  | File to update                                                                                            | String                       | Required, no default                    |
| pattern               | Regular expression to select lines                                                                        | Regular expression or String | Required, no default                    |
| line                  | Line contents                                                                                             | String                       | Required, no default                    |
| replace_only          | Don't append only replace matching lines                                                                  | true or false                | Default is false                        |
| remove_duplicates     | Remove duplicate lines matching pattern                                                                   | true or false                | Default is false                        |
| ignore_missing        | Don't fail if the file is missing                                                                         | true or false                | Default is true                         |
| eol                   | Alternate line end characters                                                                             | String                       | default `\n` on unix, `\r\n` on windows |
| backup                | Backup before changing                                                                                    | Boolean, Integer             | default false                           |
| owner                 | Set the `owner` of the file                                                                               | String                       | no default                              |
| group                 | Set the `group` of the file                                                                               | String                       | no default                              |
| mode                  | Set the `mode` of the file                                                                                | String, Integer              | no default                              |
| manage_symlink_source | Pass through Chef's symlink-source handling; setting it explicitly also suppresses Chef's symlink warning | true or false                | no default                              |

## Example Usage

```ruby
replace_or_add "why hello" do
  path "/some/file"
  pattern "Why hello there.*"
  line "Why hello there, you beautiful person, you."
end
```

```ruby
replace_or_add "change the love, don't add more" do
  path "/some/file"
  pattern "Why hello there.*"
  line "Why hello there, you beautiful person, you."
  replace_only true
end
```

If `manage_symlink_source` is set to `true`, Chef manages the symlink source file. If it is set to `false`, Chef disables symlink-source handling and may require the symlink to be removed before writing.
