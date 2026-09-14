# frozen_string_literal: true

# Integration roundtrip against a real CamelMailer instance.
#
# Skipped unless CAMELMAILER_API_KEY is set — never runs in CI.
#
#   CAMELMAILER_API_KEY=cm_...            (required)
#   CAMELMAILER_BASE_URL=https://...      (optional, defaults to the cloud)
#   CAMELMAILER_FROM=billing@acme.com     (required to send)
#   CAMELMAILER_TO=inbox@example.com      (required to send)
RSpec.describe "Integration roundtrip", :integration do
  before do
    skip "Set CAMELMAILER_API_KEY to run integration specs" unless ENV["CAMELMAILER_API_KEY"]
    WebMock.allow_net_connect!
  end

  after { WebMock.disable_net_connect! }

  let(:client) do
    CamelMailer::Client.new(
      api_key: ENV.fetch("CAMELMAILER_API_KEY"),
      base_url: ENV.fetch("CAMELMAILER_BASE_URL", "https://app.camelmailer.com")
    )
  end

  it "sends a message and reads it back" do
    skip "Set CAMELMAILER_FROM and CAMELMAILER_TO to send" unless ENV["CAMELMAILER_FROM"] && ENV["CAMELMAILER_TO"]

    result = client.emails.send(
      from: ENV.fetch("CAMELMAILER_FROM"),
      to: [ENV.fetch("CAMELMAILER_TO")],
      subject: "camelmailer-ruby integration roundtrip",
      text_body: "Sent by the camelmailer-ruby integration spec at #{Time.now.utc}."
    )

    expect(result[:message_id]).to be_a(Integer)

    message = client.emails.get(result[:message_id])
    expect(message[:message][:id]).to eq(result[:message_id])
  end

  it "lists templates and streams" do
    expect(client.templates.list).to have_key(:templates)
    expect(client.streams.list).to have_key(:streams)
    expect(client.stats.get).to have_key(:stats)
  end

  it "reaches the broadcast and diagnostic surfaces" do
    expect(client.campaigns.list).to have_key(:campaigns)
    expect(client.layouts.list).to have_key(:layouts)
    expect(client.inbound.list(per_page: 1)).to have_key(:inbound)
    expect(client.logs.list(per_page: 1)).to have_key(:requests)
    expect(client.logs.tags).to have_key(:tags)
  end
end
