# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-09-14

### Fixed

- `inbound` retry and bypass read `queued`. The endpoint answers with
  `requeued`, so both returned false and no error whatever happened. They
  also expose the `message` the response carries.
- The subscriber types carried a `name`. The endpoint takes an address and a
  status; a name was silently dropped, so the field promised something the
  API does not store.

## [0.2.1] - 2026-09-14

### Fixed

- The `upload_logo` documentation and spec read `:logo_url`. The endpoint
  answers with `:url`, so anyone following the README read a key that is
  never there. No call was broken; only the documented shape was wrong.

## [0.2.0] - 2026-09-14

### Fixed

- `Emails.send_batch` and `Emails.send_with_template_batch` wrapped the
  entries in `{ messages: [...] }`. The endpoint reads a bare JSON array,
  so every batch send was rejected before anything was queued. The existing
  spec asserted the wrapper, which is why it survived. Both now send the
  array as given.
- `sig/camelmailer.rbs` had a syntax error (`(module)` is not a type) and
  could not be parsed by any type checker. CI now validates it.

### Added

- `Campaigns`: `create_draft`, `create_and_send`, `list`, `list_for_stream`,
  `get`, `get_for_stream`, `update`, `send`, `cancel`. The two create
  methods hit different routes: `create_draft` writes the campaign and
  waits, `create_and_send` expands it to the stream's subscribers before
  the call returns.
- `Subscribers`: `list`, `add`, `import`, `complaint`, `remove`.
- `Layouts`: `list`, `create`, `get`, `update`, `delete`, `upload_logo`.
- `Inbound`: `list`, `get`, `retry`, `bypass`.
- `Logs`: `list`, `tags`.
- `Emails.send_to_stream` for broadcasting to a stream's subscribers.
- An optional `idempotency_key:` on every send. It travels as the
  `Idempotency-Key` header, because the body is what the server hashes to
  recognise a replay.
- `SendLimitExceededError` (429) and `InvalidIdempotentRequestError` (409).
- `Client#delete`, and request headers on `Client#post`.

## [0.1.0] - 2026-07-11

### Added

- `CamelMailer::Client` on stdlib net/http — zero runtime dependencies.
- Global configuration via `CamelMailer.configure` (api_key, base_url for self-hosted instances).
- Messaging resources: `Emails` (send, send_batch, send_with_template, send_with_template_batch, get, list, deliveries, opens, clicks, raw), `Templates` (list, create, get, update, archive, render), `Streams` (list, create, get, update, archive), `Stats` (get, deliveries), `Bounces` (list, get), `Dmarc` (summary, reports, report).
- Typed error hierarchy with `code`, `message` and `status_code` (`UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ValidationError`, `ParameterMissingError`, `ServerError`, `ConnectionError`).
- Rails integration: `:camelmailer` ActionMailer delivery method with full MIME mapping (from/to/cc/bcc/reply_to, html+text parts, attachments, custom headers, tag/stream/metadata pseudo-headers).
- RBS type signatures.

[Unreleased]: https://github.com/camelmailer/camelmailer-ruby/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/camelmailer/camelmailer-ruby/releases/tag/v0.2.2
[0.2.1]: https://github.com/camelmailer/camelmailer-ruby/releases/tag/v0.2.1
[0.2.0]: https://github.com/camelmailer/camelmailer-ruby/releases/tag/v0.2.0
[0.1.0]: https://github.com/camelmailer/camelmailer-ruby/releases/tag/v0.1.0
