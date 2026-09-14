# frozen_string_literal: true

require "camelmailer/version"
require "camelmailer/errors"
require "camelmailer/client"
require "camelmailer/resource"
require "camelmailer/emails"
require "camelmailer/templates"
require "camelmailer/streams"
require "camelmailer/stats"
require "camelmailer/bounces"
require "camelmailer/dmarc"
require "camelmailer/campaigns"
require "camelmailer/subscribers"
require "camelmailer/layouts"
require "camelmailer/inbound"
require "camelmailer/logs"

# The Ruby SDK for CamelMailer — https://camelmailer.com
#
#   CamelMailer.configure do |config|
#     config.api_key = "cm_..."
#     config.base_url = "https://mail.example.com" # optional, for self-hosted
#   end
#
#   CamelMailer::Emails.send(from: "a@acme.com", to: ["b@example.com"],
#                            subject: "Hello", text_body: "Hi!")
#
# Or with an explicit client (no global state):
#
#   client = CamelMailer::Client.new(api_key: "cm_...")
#   client.emails.send(...)
module CamelMailer
  DEFAULT_BASE_URL = "https://app.camelmailer.com"

  class << self
    attr_accessor :api_key
    attr_writer :base_url

    def base_url
      @base_url || DEFAULT_BASE_URL
    end

    def configure
      yield self if block_given?
      self
    end
    alias config configure

    # A client built from the global configuration.
    def client
      Client.new(api_key: api_key, base_url: base_url)
    end

    # Clears the global configuration (used in tests).
    def reset!
      @api_key = nil
      @base_url = nil
    end
  end
end

require "camelmailer/railtie" if defined?(Rails::Railtie)
