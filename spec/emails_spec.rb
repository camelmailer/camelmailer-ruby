# frozen_string_literal: true

RSpec.describe CamelMailer::Emails do
  subject(:emails) { CamelMailer::Client.new(api_key: "cm_test_key").emails }

  describe "#send" do
    it "posts the payload to /messages and returns the send result" do
      params = { from: "billing@acme.com", to: ["ada@example.com"], subject: "Receipt", text_body: "Thanks!" }
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages")
             .with(body: JSON.generate(params), headers: { "Content-Type" => "application/json" })
             .to_return(status: 201,
                        body: success_json({ message_id: 42,
                                             recipients: [{ rcpt_to: "ada@example.com", status: "queued" }] }),
                        headers: json_headers)

      result = emails.send(params)

      expect(stub).to have_been_requested
      expect(result[:message_id]).to eq(42)
      expect(result[:recipients].first[:status]).to eq("queued")
    end

    it "raises ValidationError on invalid payloads" do
      stub_error(:post, "messages", code: "ValidationError", message: "from domain not verified", status: 422)

      expect { emails.send({ from: "x@y.z", to: ["a@b.c"] }) }
        .to raise_error(CamelMailer::ValidationError, "from domain not verified")
    end
  end

  describe "#send_batch" do
    it "wraps the entries in a messages array" do
      entries = [{ from: "a@acme.com", to: ["x@e.com"] }, { from: "a@acme.com", to: ["y@e.com"] }]
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages/batch")
             .with(body: JSON.generate({ messages: entries }))
             .to_return(status: 200, body: success_json({ results: [] }), headers: json_headers)

      emails.send_batch(entries)
      expect(stub).to have_been_requested
    end
  end

  describe "#send_with_template" do
    it "posts to /messages/with_template" do
      params = { from: "hello@acme.com", to: ["ada@example.com"], template: "welcome",
                 template_model: { name: "Ada" } }
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages/with_template")
             .with(body: JSON.generate(params))
             .to_return(status: 201, body: success_json({ message_id: 7 }), headers: json_headers)

      expect(emails.send_with_template(params)[:message_id]).to eq(7)
      expect(stub).to have_been_requested
    end

    it "raises NotFoundError when the template does not exist" do
      stub_error(:post, "messages/with_template", code: "NotFound", message: "unknown template", status: 404)

      expect { emails.send_with_template({ from: "a@b.c", to: ["x@y.z"], template: "nope" }) }
        .to raise_error(CamelMailer::NotFoundError)
    end
  end

  describe "#send_with_template_batch" do
    it "posts the batch to /messages/with_template/batch" do
      entries = [{ from: "a@acme.com", to: ["x@e.com"], template: "welcome" }]
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages/with_template/batch")
             .with(body: JSON.generate({ messages: entries }))
             .to_return(status: 200, body: success_json, headers: json_headers)

      emails.send_with_template_batch(entries)
      expect(stub).to have_been_requested
    end
  end

  describe "#get" do
    it "fetches a message by id" do
      stub_success(:get, "messages/42", data: { message: { id: 42, subject: "Receipt" } })

      expect(emails.get(42)[:message][:id]).to eq(42)
    end
  end

  describe "#list" do
    it "passes filters as query params" do
      stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/messages")
             .with(query: { "scope" => "outgoing", "status" => "Sent", "tag" => "receipt",
                            "query" => "ada", "page" => "1", "per_page" => "50" })
             .to_return(status: 200, body: success_json({ messages: [], pagination: { page: 1 } }),
                        headers: json_headers)

      result = emails.list(scope: "outgoing", status: "Sent", tag: "receipt", query: "ada", page: 1, per_page: 50)
      expect(result[:messages]).to eq([])
      expect(stub).to have_been_requested
    end
  end

  describe "message details" do
    it "fetches deliveries" do
      stub_success(:get, "messages/1/deliveries", data: { deliveries: [] })
      expect(emails.deliveries(1)).to eq({ deliveries: [] })
    end

    it "fetches opens" do
      stub_success(:get, "messages/1/opens", data: { opens: [] })
      expect(emails.opens(1)).to eq({ opens: [] })
    end

    it "fetches clicks" do
      stub_success(:get, "messages/1/clicks", data: { clicks: [] })
      expect(emails.clicks(1)).to eq({ clicks: [] })
    end

    it "fetches the raw message source" do
      stub_success(:get, "messages/1/raw", data: { raw: "From: a@b.c" })
      expect(emails.raw(1)[:raw]).to start_with("From:")
    end
  end

  describe "module-level convenience" do
    it "uses the globally configured client" do
      configure_key!
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/messages")
             .with(headers: { "X-Server-API-Key" => "cm_test_key" })
             .to_return(status: 201, body: success_json({ message_id: 1 }), headers: json_headers)

      described_class.send({ from: "a@b.c", to: ["x@y.z"], subject: "hi", text_body: "yo" })
      expect(stub).to have_been_requested
    end

    it "raises without global configuration" do
      expect { described_class.send({ from: "a@b.c", to: ["x@y.z"] }) }
        .to raise_error(CamelMailer::Error, /API key/i)
    end
  end
end
