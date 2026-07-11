# frozen_string_literal: true

require "camelmailer/mailer"

RSpec.describe CamelMailer::Mailer do
  subject(:mailer) { described_class.new(api_key: "cm_test_key") }

  def sent_body(stub_uri = "#{EnvelopeHelpers::BASE}/messages", data: { message_id: 42 })
    body = nil
    stub_request(:post, stub_uri)
      .with { |req| body = JSON.parse(req.body) }
      .to_return(status: 201, body: success_json(data), headers: json_headers)
    yield
    body
  end

  describe "#deliver!" do
    it "sends a plain-text mail" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Your receipt"
        body    "Thanks for your purchase."
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body).to include(
        "from" => "billing@acme.com",
        "to" => ["ada@example.com"],
        "subject" => "Your receipt",
        "text_body" => "Thanks for your purchase."
      )
      expect(body).not_to have_key("html_body")
    end

    it "sends an HTML mail" do
      mail = Mail.new do
        from         "billing@acme.com"
        to           "ada@example.com"
        subject      "Hello"
        content_type "text/html; charset=UTF-8"
        body         "<h1>Hello</h1>"
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body["html_body"]).to eq("<h1>Hello</h1>")
      expect(body).not_to have_key("text_body")
    end

    it "sends both parts of a multipart mail" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"

        text_part do
          body "plain hello"
        end

        html_part do
          content_type "text/html; charset=UTF-8"
          body "<p>html hello</p>"
        end
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body["text_body"]).to eq("plain hello")
      expect(body["html_body"]).to eq("<p>html hello</p>")
    end

    it "maps cc, bcc and reply_to" do
      mail = Mail.new do
        from     "billing@acme.com"
        to       "ada@example.com"
        cc       "cc@example.com"
        bcc      "bcc@example.com"
        reply_to "support@acme.com"
        subject  "Hello"
        body     "hi"
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body["cc"]).to eq(["cc@example.com"])
      expect(body["bcc"]).to eq(["bcc@example.com"])
      expect(body["reply_to"]).to eq(["support@acme.com"])
    end

    it "keeps display names as address objects" do
      mail = Mail.new do
        from    "Acme Billing <billing@acme.com>"
        to      "Ada Lovelace <ada@example.com>"
        subject "Hello"
        body    "hi"
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body["from"]).to eq({ "email" => "billing@acme.com", "name" => "Acme Billing" })
      expect(body["to"]).to eq([{ "email" => "ada@example.com", "name" => "Ada Lovelace" }])
    end

    it "forwards custom headers and drops structural ones" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end
      mail["X-Entity-Ref-ID"] = "abc-123"

      body = sent_body { mailer.deliver!(mail) }

      expect(body["headers"]).to eq({ "X-Entity-Ref-ID" => "abc-123" })
    end

    it "omits the headers key when no custom headers are present" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      body = sent_body { mailer.deliver!(mail) }

      expect(body).not_to have_key("headers")
    end

    it "extracts tag and stream pseudo-headers" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end
      mail["tag"] = "receipt"
      mail["stream"] = "transactional"

      body = sent_body { mailer.deliver!(mail) }

      expect(body["tag"]).to eq("receipt")
      expect(body["stream"]).to eq("transactional")
      expect(body).not_to have_key("headers")
    end

    it "encodes attachments as base64" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Invoice"
        body    "see attachment"
      end
      mail.add_file(filename: "invoice.pdf", content: "%PDF-1.4 fake")

      body = sent_body { mailer.deliver!(mail) }

      attachment = body["attachments"].first
      expect(attachment["name"]).to eq("invoice.pdf")
      expect(attachment["content_type"]).to eq("application/pdf")
      expect(attachment["data_base64"]).to eq(["%PDF-1.4 fake"].pack("m0"))
      expect(body["text_body"]).to eq("see attachment")
    end

    it "assigns the returned message id to the mail object" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      sent_body { mailer.deliver!(mail) }

      expect(mail.message_id).to eq("42")
    end

    it "returns the API response data" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      result = nil
      sent_body { result = mailer.deliver!(mail) }

      expect(result[:message_id]).to eq(42)
    end

    it "propagates API errors" do
      stub_error(:post, "messages", code: "ValidationError", message: "from domain not verified", status: 422)

      mail = Mail.new do
        from    "billing@unverified.test"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      expect { mailer.deliver!(mail) }.to raise_error(CamelMailer::ValidationError)
    end
  end

  describe "configuration" do
    it "falls back to the global API key" do
      configure_key!
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages")
             .with(headers: { "X-Server-API-Key" => "cm_test_key" })
             .to_return(status: 201, body: success_json({ message_id: 1 }), headers: json_headers)

      described_class.new({}).deliver!(mail)
      expect(stub).to have_been_requested
    end

    it "honours a base_url override in the settings" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      stub = stub_request(:post, "https://mail.example.com/api/v2/server/messages")
             .to_return(status: 201, body: success_json({ message_id: 1 }), headers: json_headers)

      described_class.new(api_key: "k", base_url: "https://mail.example.com").deliver!(mail)
      expect(stub).to have_been_requested
    end

    it "raises without any API key" do
      mail = Mail.new do
        from    "billing@acme.com"
        to      "ada@example.com"
        subject "Hello"
        body    "hi"
      end

      expect { described_class.new({}).deliver!(mail) }.to raise_error(CamelMailer::Error, /API key/i)
    end
  end
end
