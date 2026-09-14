# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

module CamelMailer
  # HTTP client for the CamelMailer messaging API (/api/v2/server).
  #
  #   client = CamelMailer::Client.new(api_key: "cm_...")
  #   client.emails.send(from: "a@acme.com", to: ["b@example.com"], subject: "Hi", text_body: "Hello")
  #
  # Built on net/http — the gem has no runtime dependencies.
  class Client
    API_PREFIX = "/api/v2/server"

    NETWORK_ERRORS = [
      SocketError, EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET,
      Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::EPIPE,
      Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
    ].freeze

    attr_reader :api_key, :base_url, :open_timeout, :read_timeout

    def initialize(api_key:, base_url: nil, open_timeout: 10, read_timeout: 30)
      if api_key.nil? || api_key.to_s.strip.empty?
        raise Error, "No CamelMailer API key provided — set CamelMailer.api_key or pass api_key:"
      end

      @api_key = api_key
      @base_url = (base_url || DEFAULT_BASE_URL).to_s.chomp("/")
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    # The resource each accessor returns, memoized per client so
    # +client.emails+ is the same object every time. Named by constant
    # rather than by class, because the resource files are required after
    # this one.
    RESOURCES = {
      emails: :Emails, templates: :Templates, streams: :Streams,
      stats: :Stats, bounces: :Bounces, dmarc: :Dmarc,
      campaigns: :Campaigns, subscribers: :Subscribers, layouts: :Layouts,
      inbound: :Inbound, logs: :Logs
    }.freeze

    RESOURCES.each do |name, const|
      define_method(name) do
        (@resources ||= {})[name] ||= CamelMailer.const_get(const).new(self)
      end
    end

    def get(path, query = nil)
      perform(Net::HTTP::Get.new(build_uri(path, query)))
    end

    # +headers+ carries request headers such as Idempotency-Key, which
    # belong outside the body: the body is what the server hashes to
    # recognise the same request.
    def post(path, body = nil, headers = {})
      req = Net::HTTP::Post.new(build_uri(path))
      attach_body(req, body)
      perform(req, headers)
    end

    def patch(path, body = nil)
      req = Net::HTTP::Patch.new(build_uri(path))
      attach_body(req, body)
      perform(req)
    end

    def delete(path)
      perform(Net::HTTP::Delete.new(build_uri(path)))
    end

    private

    def build_uri(path, query = nil)
      uri = URI.parse("#{base_url}#{API_PREFIX}/#{path}")
      if query
        params = query.compact
        uri.query = URI.encode_www_form(params) unless params.empty?
      end
      uri
    end

    def attach_body(req, body)
      return unless body

      req["Content-Type"] = "application/json"
      req.body = JSON.generate(body)
    end

    def perform(req, headers = {})
      req["X-Server-API-Key"] = api_key
      req["Accept"] = "application/json"
      req["User-Agent"] = "camelmailer-ruby/#{VERSION}"
      headers.each { |name, value| req[name.to_s] = value.to_s }

      handle(transport(req.uri).request(req))
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, "Could not reach the CamelMailer API: #{e.class}: #{e.message}"
    end

    def transport(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout
      http
    end

    def handle(res)
      status = res.code.to_i
      body = parse_body(res.body)

      case body
      in { status: "success" }
        body[:data] || {}
      in { status: "error" }
        error = body[:error] || {}
        raise APIError.for(code: error[:code], message: error[:message], status_code: status)
      else
        return body.is_a?(Hash) ? body : {} if (200..299).cover?(status)

        raise ServerError.new("Unexpected HTTP #{status} response from the CamelMailer API", status_code: status)
      end
    end

    def parse_body(raw)
      return nil if raw.nil? || raw.empty?

      JSON.parse(raw, symbolize_names: true)
    rescue JSON::ParserError
      nil
    end
  end
end
