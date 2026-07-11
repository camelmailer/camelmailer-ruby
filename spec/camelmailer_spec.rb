# frozen_string_literal: true

RSpec.describe CamelMailer do
  it "has a version number" do
    expect(CamelMailer::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".configure" do
    it "yields the module for configuration" do
      described_class.configure do |c|
        c.api_key = "cm_key"
        c.base_url = "https://mail.example.com"
      end

      expect(described_class.api_key).to eq("cm_key")
      expect(described_class.base_url).to eq("https://mail.example.com")
    end

    it "defaults the base URL to the CamelMailer cloud" do
      expect(described_class.base_url).to eq("https://app.camelmailer.com")
    end
  end

  describe ".client" do
    it "builds a client from the global configuration" do
      described_class.configure { |c| c.api_key = "cm_key" }

      client = described_class.client
      expect(client).to be_a(CamelMailer::Client)
      expect(client.api_key).to eq("cm_key")
      expect(client.base_url).to eq("https://app.camelmailer.com")
    end

    it "raises when no API key is configured" do
      expect { described_class.client }.to raise_error(CamelMailer::Error, /API key/i)
    end
  end

  describe ".reset!" do
    it "clears the configuration" do
      described_class.configure { |c| c.api_key = "cm_key" }
      described_class.reset!
      expect(described_class.api_key).to be_nil
      expect(described_class.base_url).to eq("https://app.camelmailer.com")
    end
  end
end
