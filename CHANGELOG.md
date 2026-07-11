# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-11

### Added

- `CamelMailer::Client` on stdlib net/http — zero runtime dependencies.
- Global configuration via `CamelMailer.configure` (api_key, base_url for self-hosted instances).
- Messaging resources: `Emails` (send, send_batch, send_with_template, send_with_template_batch, get, list, deliveries, opens, clicks, raw), `Templates` (list, create, get, update, archive, render), `Streams` (list, create, get, update, archive), `Stats` (get, deliveries), `Bounces` (list, get), `Dmarc` (summary, reports, report).
- Typed error hierarchy with `code`, `message` and `status_code` (`UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ValidationError`, `ParameterMissingError`, `ServerError`, `ConnectionError`).
- Rails integration: `:camelmailer` ActionMailer delivery method with full MIME mapping (from/to/cc/bcc/reply_to, html+text parts, attachments, custom headers, tag/stream/metadata pseudo-headers).
- RBS type signatures.

[Unreleased]: https://github.com/camelmailer/camelmailer-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/camelmailer/camelmailer-ruby/releases/tag/v0.1.0
