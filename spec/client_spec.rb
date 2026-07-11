# frozen_string_literal: true

RSpec.describe CamelMailer::Client do
  subject(:client) { described_class.new(api_key: "cm_test_key") }

  describe "#initialize" do
    it "requires an API key" do
      expect { described_class.new(api_key: nil) }.to raise_error(CamelMailer::Error, /API key/i)
      expect { described_class.new(api_key: "") }.to raise_error(CamelMailer::Error, /API key/i)
    end

    it "defaults to the cloud base URL" do
      expect(client.base_url).to eq("https://app.camelmailer.com")
    end

    it "accepts a custom base URL and strips trailing slashes" do
      c = described_class.new(api_key: "k", base_url: "https://mail.example.com/")
      expect(c.base_url).to eq("https://mail.example.com")
    end
  end

  describe "authentication and headers" do
    it "sends the X-Server-API-Key and user agent" do
      stub = stub_request(:get, "https://app.camelmailer.com/api/v2/server/ping")
             .with(headers: {
                     "X-Server-API-Key" => "cm_test_key",
                     "Accept" => "application/json",
                     "User-Agent" => "camelmailer-ruby/#{CamelMailer::VERSION}"
                   })
             .to_return(status: 200, body: success_json, headers: json_headers)

      client.get("ping")
      expect(stub).to have_been_requested
    end
  end

  describe "response handling" do
    it "returns the data payload with symbolized keys" do
      stub_success(:get, "messages/1", data: { "message" => { "id" => 1, "tag" => "x" } })

      expect(client.get("messages/1")).to eq({ message: { id: 1, tag: "x" } })
    end

    it "symbolizes nested arrays" do
      stub_success(:get, "streams", data: { "streams" => [{ "id" => 1 }, { "id" => 2 }] })

      expect(client.get("streams")).to eq({ streams: [{ id: 1 }, { id: 2 }] })
    end

    it "returns an empty hash when data is absent" do
      stub_request(:get, "https://app.camelmailer.com/api/v2/server/ping")
        .to_return(status: 200, body: JSON.generate({ status: "success", time: 0.1 }), headers: json_headers)

      expect(client.get("ping")).to eq({})
    end
  end

  describe "query parameters" do
    it "encodes query params and drops nils" do
      stub = stub_request(:get, "https://app.camelmailer.com/api/v2/server/messages")
             .with(query: { "page" => "2", "tag" => "receipt" })
             .to_return(status: 200, body: success_json, headers: json_headers)

      client.get("messages", { page: 2, tag: "receipt", status: nil })
      expect(stub).to have_been_requested
    end
  end

  describe "error handling" do
    it "raises UnauthorizedError with code, message and status_code" do
      stub_error(:get, "messages", code: "Unauthorized", message: "invalid key", status: 401)

      expect { client.get("messages") }.to raise_error(CamelMailer::UnauthorizedError) do |e|
        expect(e.code).to eq("Unauthorized")
        expect(e.message).to eq("invalid key")
        expect(e.status_code).to eq(401)
      end
    end

    it "raises ValidationError for validation failures" do
      stub_error(:post, "messages", code: "ValidationError", message: "from is invalid", status: 422)

      expect { client.post("messages", { from: "x" }) }.to raise_error(CamelMailer::ValidationError) do |e|
        expect(e.code).to eq("ValidationError")
        expect(e.status_code).to eq(422)
      end
    end

    it "raises NotFoundError" do
      stub_error(:get, "messages/9", code: "NotFound", message: "no such message", status: 404)

      expect { client.get("messages/9") }.to raise_error(CamelMailer::NotFoundError)
    end

    it "raises ForbiddenError" do
      stub_error(:get, "messages", code: "Forbidden", message: "nope", status: 403)

      expect { client.get("messages") }.to raise_error(CamelMailer::ForbiddenError)
    end

    it "raises ParameterMissingError" do
      stub_error(:post, "messages", code: "ParameterMissing", message: "to is required", status: 400)

      expect { client.post("messages", {}) }.to raise_error(CamelMailer::ParameterMissingError)
    end

    it "raises APIError for unknown error codes" do
      stub_error(:get, "messages", code: "SomethingNew", message: "eh", status: 400)

      expect { client.get("messages") }.to raise_error(CamelMailer::APIError) do |e|
        expect(e.code).to eq("SomethingNew")
      end
    end

    it "raises ServerError for non-JSON 5xx responses" do
      stub_request(:get, "https://app.camelmailer.com/api/v2/server/messages")
        .to_return(status: 502, body: "<html>bad gateway</html>")

      expect { client.get("messages") }.to raise_error(CamelMailer::ServerError) do |e|
        expect(e.status_code).to eq(502)
      end
    end

    it "raises ConnectionError on network failures" do
      stub_request(:get, "https://app.camelmailer.com/api/v2/server/ping").to_raise(Errno::ECONNREFUSED)

      expect { client.get("ping") }.to raise_error(CamelMailer::ConnectionError)
    end

    it "raises ConnectionError on timeouts" do
      stub_request(:get, "https://app.camelmailer.com/api/v2/server/ping").to_timeout

      expect { client.get("ping") }.to raise_error(CamelMailer::ConnectionError)
    end

    it "keeps the error hierarchy rooted at CamelMailer::Error" do
      expect(CamelMailer::UnauthorizedError.ancestors).to include(CamelMailer::APIError, CamelMailer::Error)
      expect(CamelMailer::ConnectionError.ancestors).to include(CamelMailer::Error)
    end
  end

  describe "resource accessors" do
    it "exposes all messaging resources" do
      expect(client.emails).to be_a(CamelMailer::Emails)
      expect(client.templates).to be_a(CamelMailer::Templates)
      expect(client.streams).to be_a(CamelMailer::Streams)
      expect(client.stats).to be_a(CamelMailer::Stats)
      expect(client.bounces).to be_a(CamelMailer::Bounces)
      expect(client.dmarc).to be_a(CamelMailer::Dmarc)
    end

    it "memoizes resource instances" do
      expect(client.emails).to equal(client.emails)
    end
  end
end
