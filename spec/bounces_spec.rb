# frozen_string_literal: true

RSpec.describe CamelMailer::Bounces do
  subject(:bounces) { CamelMailer::Client.new(api_key: "cm_test_key").bounces }

  it "lists bounces" do
    stub_success(:get, "bounces", data: { messages: [] })

    expect(bounces.list).to eq({ messages: [] })
  end

  it "passes pagination filters" do
    stub = stub_request(:get, "#{EnvelopeHelpers::BASE}/bounces")
           .with(query: { "page" => "2", "per_page" => "10" })
           .to_return(status: 200, body: success_json({ messages: [] }), headers: json_headers)

    bounces.list(page: 2, per_page: 10)
    expect(stub).to have_been_requested
  end

  it "shows a bounce" do
    stub_success(:get, "bounces/5", data: { message: { id: 5, bounce: true } })

    expect(bounces.get(5)[:message][:bounce]).to be(true)
  end

  it "raises NotFoundError for unknown bounces" do
    stub_error(:get, "bounces/9", code: "NotFound", message: "not found", status: 404)

    expect { bounces.get(9) }.to raise_error(CamelMailer::NotFoundError)
  end

  it "works at module level with global config" do
    configure_key!
    stub_success(:get, "bounces", data: { messages: [] })

    expect(described_class.list).to eq({ messages: [] })
  end
end
