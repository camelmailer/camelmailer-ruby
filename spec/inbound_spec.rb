# frozen_string_literal: true

RSpec.describe CamelMailer::Inbound do
  subject(:inbound) { CamelMailer::Client.new(api_key: "cm_test_key").inbound }

  it "lists with filters in the query string" do
    stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/inbound")
           .with(query: { status: "held", per_page: "50" })
           .to_return(status: 200, body: success_json({ inbound: [] }), headers: json_headers)

    inbound.list(status: "held", per_page: 50)
    expect(stub).to have_been_requested
  end

  it "fetches one message" do
    stub_success(:get, "inbound/55", data: { message: { id: 55, status: "held" } })

    expect(inbound.get(55)[:message][:status]).to eq("held")
  end

  it "retries and bypasses" do
    retry_stub = stub_success(:post, "inbound/55/retry", data: { queued: true })
    bypass_stub = stub_success(:post, "inbound/55/bypass", data: { queued: true })

    inbound.retry(55)
    inbound.bypass(55)

    expect(retry_stub).to have_been_requested
    expect(bypass_stub).to have_been_requested
  end
end
