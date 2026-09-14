# frozen_string_literal: true

RSpec.describe CamelMailer::Campaigns do
  subject(:campaigns) { CamelMailer::Client.new(api_key: "cm_test_key").campaigns }

  describe "#list" do
    it "lists every campaign of the server" do
      stub_success(:get, "campaigns", data: { campaigns: [{ id: 1, name: "September" }] })

      expect(campaigns.list[:campaigns].first[:name]).to eq("September")
    end
  end

  describe "#list_for_stream" do
    it "lists the campaigns of one stream" do
      stub = stub_success(:get, "streams/newsletter/campaigns", data: { campaigns: [] })

      campaigns.list_for_stream("newsletter")
      expect(stub).to have_been_requested
    end
  end

  describe "#get" do
    it "returns the campaign with its statistics" do
      stub_success(:get, "campaigns/7", data: { campaign: { id: 7 }, stats: { sent: 120 } })

      expect(campaigns.get(7)[:stats][:sent]).to eq(120)
    end
  end

  describe "#get_for_stream" do
    it "fetches through the stream" do
      stub = stub_success(:get, "streams/newsletter/campaigns/7", data: { campaign: { id: 7 } })

      campaigns.get_for_stream("newsletter", 7)
      expect(stub).to have_been_requested
    end
  end

  describe "#create_draft" do
    it "names the stream in the body and leaves the campaign a draft" do
      params = { stream: "newsletter", name: "September", from: "news@acme.com" }
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/campaigns")
             .with(body: JSON.generate(params))
             .to_return(status: 201, body: success_json({ campaign: { id: 3, status: "draft" } }),
                        headers: json_headers)

      expect(campaigns.create_draft(params)[:campaign][:status]).to eq("draft")
      expect(stub).to have_been_requested
    end

    it "arms a schedule" do
      stub_request(:post, "#{EnvelopeHelpers::BASE}/campaigns")
        .to_return(status: 201, body: success_json({ campaign: { status: "scheduled" } }),
                   headers: json_headers)

      result = campaigns.create_draft({ stream: "newsletter", from: "news@acme.com",
                                        scheduled_at: "2026-10-01T09:00:00Z" })

      expect(result[:campaign][:status]).to eq("scheduled")
    end
  end

  describe "#create_and_send" do
    it "posts to the stream route, which expands to the subscribers right away" do
      stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/streams/newsletter/campaigns")
             .to_return(status: 201, body: success_json({ campaign: { id: 5, status: "sending" } }),
                        headers: json_headers)

      result = campaigns.create_and_send("newsletter", { name: "September", from: "news@acme.com" })

      expect(result[:campaign][:status]).to eq("sending")
      expect(stub).to have_been_requested
    end
  end

  describe "#update" do
    it "schedules by sending a time and unschedules with nil" do
      stub = stub_request(:patch, "#{EnvelopeHelpers::BASE}/campaigns/3")
             .with(body: JSON.generate({ scheduled_at: nil }))
             .to_return(status: 200, body: success_json({ campaign: { status: "draft" } }),
                        headers: json_headers)

      # nil has to survive into the body; it is what clears a schedule.
      expect(campaigns.update(3, { scheduled_at: nil })[:campaign][:status]).to eq("draft")
      expect(stub).to have_been_requested
    end

    it "refuses to edit a campaign that is already sending" do
      stub_error(:patch, "campaigns/3", code: "ValidationError", message: "a sent campaign can no longer be edited")

      expect { campaigns.update(3, { subject: "Too late" }) }.to raise_error(CamelMailer::ValidationError)
    end
  end

  describe "#send and #cancel" do
    it "sends now and cancels" do
      send_stub = stub_success(:post, "campaigns/3/send", data: { campaign: { status: "sending" } })
      cancel_stub = stub_success(:post, "campaigns/3/cancel", data: { campaign: { status: "canceled" } })

      campaigns.send(3)
      campaigns.cancel(3)

      expect(send_stub).to have_been_requested
      expect(cancel_stub).to have_been_requested
    end
  end
end
