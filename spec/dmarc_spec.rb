# frozen_string_literal: true

RSpec.describe CamelMailer::Dmarc do
  subject(:dmarc) { CamelMailer::Client.new(api_key: "cm_test_key").dmarc }

  it "fetches the compliance summary" do
    stub_success(:get, "dmarc/summary", data: { summary: { total: 100, pass: 98, pass_rate: 0.98 } })

    expect(dmarc.summary[:summary][:pass_rate]).to eq(0.98)
  end

  it "filters the summary by domain and window" do
    stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/dmarc/summary")
           .with(query: { "domain" => "acme.com", "from" => "2026-01-01T00:00:00Z" })
           .to_return(status: 200, body: success_json({ summary: {} }), headers: json_headers)

    dmarc.summary(domain: "acme.com", from: "2026-01-01T00:00:00Z")
    expect(stub).to have_been_requested
  end

  it "lists aggregate reports" do
    stub_success(:get, "dmarc/reports", data: { reports: [], pagination: { page: 1 } })

    expect(dmarc.reports[:reports]).to eq([])
  end

  it "shows a report with its records" do
    stub_success(:get, "dmarc/reports/3", data: { report: { id: 3 }, records: [{ source_ip: "203.0.113.10" }] })

    result = dmarc.report(3)
    expect(result[:report][:id]).to eq(3)
    expect(result[:records].first[:source_ip]).to eq("203.0.113.10")
  end

  it "raises NotFoundError for unknown reports" do
    stub_error(:get, "dmarc/reports/9", code: "NotFound", message: "not found", status: 404)

    expect { dmarc.report(9) }.to raise_error(CamelMailer::NotFoundError)
  end

  it "works at module level with global config" do
    configure_key!
    stub_success(:get, "dmarc/summary", data: { summary: {} })

    expect(described_class.summary).to eq({ summary: {} })
  end
end
