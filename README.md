# danger-missing_codeowners

A [Danger Ruby](https://github.com/danger/danger) plugin for inspecting [CODEOWNERS](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/about-code-owners) and finding which files have no owners.

Works with GitHub and GitLab.

## Installation

Add this line to your Gemfile:

```rb
gem 'danger-missing_codeowners'
```

## Usage

Just call the `verify` method in your Dangerfile:

```rb
missing_codeowners.verify
```

By default danger-missing_codeowners will only verify files that were added or modified in the pull request diff.

To verify all files, use the `verify_all_files` option:

```rb
missing_codeowners.verify_all_files = true
missing_codeowners.verify
```

If you want to control exactly which files should be checked, provide the files to the `verify` function:

```rb
missing_codeowners.verify(['my_file.swift'])
```

You can also adjust the severity of the execution. Possible valures are `error` (default) and `warning`:

```rb
missing_codeowners.severity = 'warning'
missing_codeowners.verify
```

### Integration Tips

After adding this plugin you may find a lot of files without CODEOWNERS. To help you during this process, you may find useful to bump the maximum number of files the plugin reports per run:

```rb
missing_codeowners.max_number_of_files_to_report = 500
```

You can also try to execute Danger locally (create a new Dangerfile with only this plugin, as other plugins may not work locally):

`danger dry_run --dangerfile=<your dangerfile> --base=<your base branch, usually main>`

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.

## Troubleshooting

### Error: invalid byte sequence in US-ASCII

Danger requires the filesystem to be encoded with UTF-8, which is usually the default.

You can try adding these lines to the top of your Dangerfile:

```rb
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
```

## License

MIT
