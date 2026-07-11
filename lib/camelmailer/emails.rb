# frozen_string_literal: true

module CamelMailer
  # Send and read messages (POST/GET /api/v2/server/messages...).
  class Emails < Resource
    expose :send, :send_batch, :send_with_template, :send_with_template_batch,
           :get, :list, :deliveries, :opens, :clicks, :raw

    # Sends one message. Required: from:, to:. See the API docs for the
    # full SendRequest shape (html_body, text_body, cc, bcc, reply_to,
    # headers, attachments, tag, metadata, stream).
    def send(params)
      client.post("messages", params)
    end

    # Sends a batch of SendRequest hashes; returns one result per entry.
    def send_batch(messages)
      client.post("messages/batch", { messages: messages })
    end

    # Renders a stored template against template_model:, then sends.
    def send_with_template(params)
      client.post("messages/with_template", params)
    end

    # Batch variant of #send_with_template.
    def send_with_template_batch(messages)
      client.post("messages/with_template/batch", { messages: messages })
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
  end
end
