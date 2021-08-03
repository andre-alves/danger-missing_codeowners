# danger-missing_codeowners

A [Danger Ruby](https://github.com/danger/danger) plugin for inspecting [CODEOWNERS](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/about-code-owners) and finding which files have no owners.

Works with GitHub and GitLab.

## Installation

Add this line to your Gemfile:

```rb
gem 'danger-missing_codeowners'
```

## Usage

Just call the `verify` methd in your Dangerfile:

```rb
missing_codeowners.verify
```

By default danger-missing_codeowners will only verify files that were added or modified in the pull request diff.

To verify all files, use the `verify_all_files` option:

```rb
missing_codeowners.verify_all_files = true
missing_codeowners.verify
```

You can also adjust the severity of the execution. Possible valures are `error` (default) and `warning`:

```rb
missing_codeowners.severity = 'warning'
missing_codeowners.verify
```

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.

## License

MIT
