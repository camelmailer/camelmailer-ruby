# frozen_string_literal: true

module CamelMailer
  # Send and read messages (POST/GET /api/v2/server/messages...).
  class Emails < Resource
    expose :send, :send_batch, :send_with_template, :send_with_template_batch,
           :send_to_stream, :get, :list, :deliveries, :opens, :clicks, :raw

    # Sends one message. Required: from:, to:. See the API docs for the
    # full SendRequest shape (html_body, text_body, cc, bcc, reply_to,
    # headers, attachments, tag, metadata, stream).
    #
    # Pass idempotency_key: to make the send replayable: the same key with
    # the same body returns the first result instead of sending twice.
    #
    # Takes the message either as a hash or as keywords, because both read
    # naturally and both were already in use:
    #
    #   emails.send(from: "a@acme.com", to: ["b@e.com"], subject: "Hi")
    #   emails.send(params, idempotency_key: "receipt-7")
    def send(params = {}, **fields)
      key = fields.delete(:idempotency_key)
      client.post("messages", params.merge(fields), idempotency_headers(key))
    end

    # Sends a batch of SendRequest hashes; returns one result per entry.
    #
    # Sent as a bare JSON array, which is what the endpoint reads.
    def send_batch(messages, idempotency_key: nil)
      client.post("messages/batch", messages, idempotency_headers(idempotency_key))
    end

    # Sends the same content to every subscriber of a broadcast stream.
    # Either give subject: with a body, or a template: permalink with an
    # optional template_model:. The response counts queued: against
    # skipped:; recipients past the per-request cap of 1000 are skipped,
    # so a larger audience wants a campaign.
    def send_to_stream(permalink, params)
      client.post("streams/#{permalink}/send", params)
    end

    # Renders a stored template against template_model:, then sends.
    # Takes idempotency_key: the same way #send does.
    def send_with_template(params = {}, **fields)
      key = fields.delete(:idempotency_key)
      client.post("messages/with_template", params.merge(fields), idempotency_headers(key))
    end

    # Batch variant of #send_with_template. Also a bare JSON array.
    def send_with_template_batch(messages, idempotency_key: nil)
      client.post("messages/with_template/batch", messages, idempotency_headers(idempotency_key))
    end

    # Shows one message by id.
    def get(id)
      client.get("messages/#{id}")
    end

    # Lists messages. Filters: scope:, status:, tag:, query:, stream:,
    # page:, per_page: (max 100).
    def list(**filters)
      client.get("messages", filters)
    end

    # Delivery attempts of a message.
    def deliveries(id)
      client.get("messages/#{id}/deliveries")
    end

    # Open events of a message.
    def opens(id)
      client.get("messages/#{id}/opens")
    end

    # Click events of a message.
    def clicks(id)
      client.get("messages/#{id}/clicks")
    end

    # Raw RFC 5322 source of a message.
    def raw(id)
      client.get("messages/#{id}/raw")
    end

    private

    def idempotency_headers(key)
      key.nil? ? {} : { "Idempotency-Key" => key }
    end
  end
end
