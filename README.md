# camelmailer-ruby

[![CI](https://github.com/camelmailer/camelmailer-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/camelmailer/camelmailer-ruby/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/camelmailer)](https://rubygems.org/gems/camelmailer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

The Ruby and Rails SDK for [Camelmailer](https://camelmailer.com) — open-source transactional email. No runtime dependencies, Ruby >= 3.1.

## Install

```sh
gem install camelmailer
# or in your Gemfile
gem "camelmailer"
```

## Quickstart

```ruby
require "camelmailer"

CamelMailer.configure { |c| c.api_key = "cm_..." }

CamelMailer::Emails.send(
  from: "billing@acme.com",
  to: ["ada@example.com"],
  subject: "Your receipt",
  html_body: "<h1>Thanks!</h1>"
)
```

Or without global state:

```ruby
client = CamelMailer::Client.new(api_key: "cm_...")
client.emails.send(from: "billing@acme.com", to: ["ada@example.com"], subject: "Hi", text_body: "Hello")
```

Every resource is available both ways: `CamelMailer::Emails.send(...)` uses the global configuration, `client.emails.send(...)` uses an explicit client.

## Self-hosted

The base URL defaults to the Camelmailer cloud (`https://app.camelmailer.com`). Point it at your own instance:

```ruby
CamelMailer.configure do |c|
  c.api_key = "cm_..."
  c.base_url = "https://mail.example.com"
end
```

## Rails

The gem registers the `:camelmailer` ActionMailer delivery method automatically:

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :camelmailer
config.action_mailer.camelmailer_settings = {
  api_key: Rails.application.credentials.dig(:camelmailer, :api_key),
  base_url: "https://mail.example.com" # optional, self-hosted only
}
```

Then use ActionMailer as usual — including attachments, multipart bodies and custom headers:

```ruby
class ReceiptMailer < ApplicationMailer
  def receipt
    attachments["invoice.pdf"] = File.read("invoice.pdf")
    mail(
      from: "billing@acme.com",
      to: params[:to],
      subject: "Your receipt",
      tag: "receipt",              # CamelMailer tag (filtering & stats)
      stream: "transactional"      # optional message stream
    )
  end
end
```

## Resources

### Emails

```ruby
CamelMailer::Emails.send(from:, to:, subject:, html_body:, text_body:, cc:, bcc:, reply_to:, headers:, attachments:, tag:, metadata:, stream:)
CamelMailer::Emails.send_batch([{ from:, to:, ... }, ...])
CamelMailer::Emails.send_with_template(from:, to:, template: "welcome", template_model: { name: "Ada" })
CamelMailer::Emails.send_with_template_batch([...])
CamelMailer::Emails.send_to_stream("newsletter", from:, subject:, text_body:)
CamelMailer::Emails.get(42)
CamelMailer::Emails.list(scope: "outgoing", status: "Sent", tag: "receipt", query: "ada", page: 1, per_page: 50)
CamelMailer::Emails.deliveries(42)  # delivery attempts
CamelMailer::Emails.opens(42)       # open events
CamelMailer::Emails.clicks(42)      # click events
CamelMailer::Emails.raw(42)         # raw RFC 5322 source
```

Attachments are `{ name:, content_type:, data_base64: }`; addresses are either `"a@b.com"` or `{ email: "a@b.com", name: "Ada" }`.

`send_to_stream` broadcasts to everyone subscribed to a stream, up to 1000
per call; the response counts `queued:` against `skipped:`, so a larger
audience wants a campaign.

Every send takes an optional `idempotency_key:`, which makes it replayable:
the same key with the same body returns the first result instead of sending
twice, and a different body under the same key raises
`CamelMailer::InvalidIdempotentRequestError`.

```ruby
CamelMailer::Emails.send(from: "billing@acme.com", to: ["ada@example.com"],
                         subject: "Your receipt", idempotency_key: "receipt-#{order.id}")
```

### Templates

```ruby
CamelMailer::Templates.list
CamelMailer::Templates.create(name: "Welcome", subject: "Hi {{ name }}", html_body: "<p>Hi {{ name }}</p>")
CamelMailer::Templates.get("welcome")
CamelMailer::Templates.update("welcome", subject: "Hello {{ name }}")
CamelMailer::Templates.archive("welcome")
CamelMailer::Templates.render("welcome", { name: "Ada" }) # preview without sending
```

### Streams

```ruby
CamelMailer::Streams.list
CamelMailer::Streams.create(name: "Broadcasts", stream_type: "broadcast")
CamelMailer::Streams.get("broadcasts")
CamelMailer::Streams.update("broadcasts", name: "News")
CamelMailer::Streams.archive("broadcasts")
```

### Campaigns

A campaign is content plus an audience. The two ways to create one behave
differently, so pick deliberately: `create_draft` writes it and waits,
`create_and_send` expands it to the stream's subscribers before the call
returns.

```ruby
CamelMailer::Campaigns.create_draft(stream: "newsletter", name: "September",
                                    from: "news@acme.com", subject: "What shipped",
                                    text_body: "Hello.")
# scheduled_at: "2026-10-01T09:00:00Z" arms it as `scheduled`
# send_now: true sends it on creation

CamelMailer::Campaigns.create_and_send("newsletter", name: "Status update",
                                       from: "news@acme.com", text_body: "All clear.")

CamelMailer::Campaigns.list
CamelMailer::Campaigns.list_for_stream("newsletter")
CamelMailer::Campaigns.get(7)                      # with stats
CamelMailer::Campaigns.get_for_stream("newsletter", 7)
CamelMailer::Campaigns.update(7, subject: "Corrected")
CamelMailer::Campaigns.update(7, scheduled_at: nil) # back to draft
CamelMailer::Campaigns.send(7)                      # now, whatever the schedule said
CamelMailer::Campaigns.cancel(7)
```

### Subscribers

A broadcast send to an address that is not subscribed is refused, so this
list is the audience.

```ruby
CamelMailer::Subscribers.list("newsletter")
CamelMailer::Subscribers.add("newsletter", address: "ada@example.com", name: "Ada")
CamelMailer::Subscribers.import("newsletter", ["ada@example.com", "grace@example.com"])
CamelMailer::Subscribers.complaint("newsletter", "ada@example.com") # suppress + unsubscribe
CamelMailer::Subscribers.remove("newsletter", "ada@example.com")
```

### Layouts

A layout wraps every template that uses it. `html_wrapper` has to embed the
body with `{{{ content }}}`.

```ruby
CamelMailer::Layouts.list
CamelMailer::Layouts.create(name: "Default", permalink: "default",
                            html_wrapper: "<html><body>{{{ content }}}</body></html>")
CamelMailer::Layouts.get("default")
CamelMailer::Layouts.update("default", name: "Main")
CamelMailer::Layouts.upload_logo("default", "data:image/png;base64,...")
CamelMailer::Layouts.delete("default")
```

### Inbound and held messages

```ruby
CamelMailer::Inbound.list(status: "held")
CamelMailer::Inbound.get(55)
CamelMailer::Inbound.retry(55)   # back on the delivery queue
CamelMailer::Inbound.bypass(55)  # release past the hold
```

### Logs

Useful when a send did not arrive and the question is whether the request
ever reached the API.

```ruby
CamelMailer::Logs.list(per_page: 25)
CamelMailer::Logs.tags
```

### Stats & bounces

```ruby
CamelMailer::Stats.get(from: "2026-01-01T00:00:00Z", to: "2026-02-01T00:00:00Z")
CamelMailer::Stats.deliveries
CamelMailer::Bounces.list(page: 1, per_page: 50)
CamelMailer::Bounces.get(42)
```

### DMARC

```ruby
CamelMailer::Dmarc.summary(domain: "acme.com")
CamelMailer::Dmarc.reports(domain: "acme.com", page: 1)
CamelMailer::Dmarc.report(3)
```

## Error handling

All API errors raise typed exceptions with `code`, `message` and `status_code`:

```ruby
begin
  CamelMailer::Emails.send(from: "x@unverified.test", to: ["a@b.com"])
rescue CamelMailer::ValidationError => e
  e.code        # => "ValidationError"
  e.message     # => "from domain not verified"
  e.status_code # => 422
rescue CamelMailer::UnauthorizedError
  # bad API key
rescue CamelMailer::ConnectionError
  # network problem
rescue CamelMailer::Error => e
  # everything above inherits from this
end
```

Hierarchy: `Error` → `ConnectionError`, `APIError` → `UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ValidationError`, `ParameterMissingError`, `ServerError`.

## Docs

Full API reference: [camelmailer.com/docs](https://camelmailer.com/docs)

## License

[MIT](LICENSE)
