# frozen_string_literal: true

RSpec.describe CamelMailer::Streams do
  subject(:streams) { CamelMailer::Client.new(api_key: "cm_test_key").streams }

  it "lists streams" do
    stub_success(:get, "streams", data: { streams: [] })

    expect(streams.list).to eq({ streams: [] })
  end

  it "creates a stream" do
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/streams")
           .with(body: JSON.generate({ name: "Broadcasts", stream_type: "broadcast" }))
           .to_return(status: 201, body: success_json({ stream: { permalink: "broadcasts" } }),
                      headers: json_headers)

    expect(streams.create({ name: "Broadcasts", stream_type: "broadcast" })[:stream][:permalink])
      .to eq("broadcasts")
    expect(stub).to have_been_requested
  end

  it "shows a stream" do
    stub_success(:get, "streams/broadcasts", data: { stream: { permalink: "broadcasts" } })

    expect(streams.get("broadcasts")[:stream][:permalink]).to eq("broadcasts")
  end

  it "updates a stream" do
    stub = stub_request(:patch, "#{EnvelopeHelpers::BASE}/streams/broadcasts")
           .with(body: JSON.generate({ name: "News" }))
           .to_return(status: 200, body: success_json, headers: json_headers)

    streams.update("broadcasts", { name: "News" })
    expect(stub).to have_been_requested
  end

  it "archives a stream" do
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/streams/broadcasts/archive")
           .to_return(status: 200, body: success_json, headers: json_headers)

    streams.archive("broadcasts")
    expect(stub).to have_been_requested
  end

  it "propagates authorization errors" do
    stub_error(:get, "streams", code: "Unauthorized", message: "bad key", status: 401)

    expect { streams.list }.to raise_error(CamelMailer::UnauthorizedError)
  end

  it "works at module level with global config" do
    configure_key!
    stub_success(:get, "streams", data: { streams: [] })

    expect(described_class.list).to eq({ streams: [] })
  end
end
