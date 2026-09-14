# frozen_string_literal: true

RSpec.describe CamelMailer::Logs do
  subject(:logs) { CamelMailer::Client.new(api_key: "cm_test_key").logs }

  it "lists logged requests" do
    stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/logs")
           .with(query: { per_page: "25" })
           .to_return(status: 200, body: success_json({ requests: [] }), headers: json_headers)

    logs.list(per_page: 25)
    expect(stub).to have_been_requested
  end

  it "lists tags with their counts" do
    stub_success(:get, "tags", data: { tags: [{ tag: "receipt", count: 12 }] })

    expect(logs.tags[:tags].first[:count]).to eq(12)
  end
end
