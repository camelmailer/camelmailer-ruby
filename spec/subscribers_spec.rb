# frozen_string_literal: true

RSpec.describe CamelMailer::Subscribers do
  subject(:subscribers) { CamelMailer::Client.new(api_key: "cm_test_key").subscribers }

  describe "#list" do
    it "lists the stream's subscribers" do
      stub_success(:get, "streams/newsletter/subscribers",
                   data: { subscribers: [{ address: "ada@example.com", status: "subscribed" }] })

      expect(subscribers.list("newsletter")[:subscribers].first[:status]).to eq("subscribed")
    end
  end

  describe "#add" do
    it "upserts by address" do
      # The endpoint takes address and status; there is no name field.
      params = { address: "ada@example.com", status: "subscribed" }
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/streams/newsletter/subscribers")
             .with(body: JSON.generate(params))
             .to_return(status: 201, body: success_json({ subscriber: params }), headers: json_headers)

      subscribers.add("newsletter", params)
      expect(stub).to have_been_requested
    end
  end

  describe "#import" do
    it "sends the addresses under an addresses key" do
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/streams/newsletter/subscribers/import")
             .with(body: JSON.generate({ addresses: %w[ada@example.com grace@example.com] }))
             .to_return(status: 200, body: success_json({ added: 2, total: 2 }), headers: json_headers)

      expect(subscribers.import("newsletter", %w[ada@example.com grace@example.com])[:added]).to eq(2)
      expect(stub).to have_been_requested
    end
  end

  describe "#remove" do
    it "escapes the address so a plus survives the path" do
      stub = stub_success(:delete, "streams/newsletter/subscribers/ada%2Bnews%40example.com",
                          data: { deleted: true })

      subscribers.remove("newsletter", "ada+news@example.com")
      expect(stub).to have_been_requested
    end
  end

  describe "#complaint" do
    it "suppresses the address and unsubscribes it" do
      stub_success(:post, "streams/newsletter/subscribers/ada%40example.com/complaint",
                   data: { subscriber: { status: "unsubscribed" } })

      expect(subscribers.complaint("newsletter", "ada@example.com")[:subscriber][:status])
        .to eq("unsubscribed")
    end
  end
end
