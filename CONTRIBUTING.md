# Contributing

## Setup

```sh
git clone https://github.com/camelmailer/camelmailer-ruby
cd camelmailer-ruby
bundle install
```

Requires Ruby >= 3.1.

## Tests & lint

```sh
bundle exec rspec      # unit tests (WebMock, no network)
bundle exec rubocop    # lint
bundle exec rake       # both
```

Integration tests run against a real instance and are skipped without credentials:

```sh
CAMELMAILER_API_KEY=cm_... CAMELMAILER_BASE_URL=https://mail.example.com \
CAMELMAILER_FROM=billing@acme.com CAMELMAILER_TO=inbox@example.com \
bundle exec rspec spec/integration
```

## Conventions

- Test-first: every resource method and error path has a spec against a mocked HTTP layer.
- No runtime dependencies — stdlib `net/http` only.
- Follow the existing envelope handling in `CamelMailer::Client`; new endpoints go on the matching resource class plus an `expose` entry for the class-level API.
- Update `CHANGELOG.md` (Keep a Changelog) with user-visible changes.
