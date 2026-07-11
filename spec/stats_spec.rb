# frozen_string_literal: true

RSpec.describe CamelMailer::Stats do
  subject(:stats) { CamelMailer::Client.new(api_key: "cm_test_key").stats }

  it "fetches message counters" do
    stub_success(:get, "stats", data: { stats: { total: 10, sent: 9, bounced: 1 } })

    expect(stats.get[:stats][:total]).to eq(10)
  end

  it "passes the time window as query params" do
    stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/stats")
           .with(query: { "from" => "2026-01-01T00:00:00Z", "to" => "2026-02-01T00:00:00Z" })
           .to_return(status: 200, body: success_json({ stats: {} }), headers: json_headers)

    stats.get(from: "2026-01-01T00:00:00Z", to: "2026-02-01T00:00:00Z")
    expect(stub).to have_been_requested
  end

  it "fetches delivery statistics" do
    stub_success(:get, "stats/deliveries", data: { deliveries: { queued: 1 } })

    expect(stats.deliveries[:deliveries][:queued]).to eq(1)
  end

  it "propagates errors" do
    stub_error(:get, "stats", code: "Unauthorized", message: "bad key", status: 401)

    expect { stats.get }.to raise_error(CamelMailer::UnauthorizedError)
  end

  it "works at module level with global config" do
    configure_key!
    stub_success(:get, "stats", data: { stats: { total: 0 } })

    expect(described_class.get[:stats][:total]).to eq(0)
  end
end
