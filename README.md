# danger-missing_codeowners

A [Danger Ruby](https://github.com/danger/danger) plugin for inspecting [CODEOWNERS](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/about-code-owners) files and finding which files have no owners.

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

The plugin will only verify files that were changed in the pull request diff.

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.

## License

MIT
