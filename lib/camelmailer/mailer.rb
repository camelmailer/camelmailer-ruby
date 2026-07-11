# frozen_string_literal: true

require "camelmailer"

module CamelMailer
  # ActionMailer delivery method (:camelmailer).
  #
  #   config.action_mailer.delivery_method = :camelmailer
  #   config.action_mailer.camelmailer_settings = {
  #     api_key: Rails.application.credentials.dig(:camelmailer, :api_key),
  #     base_url: "https://mail.example.com" # optional, for self-hosted
  #   }
  #
  # Falls back to the global CamelMailer.configure settings when the
  # delivery-method settings do not provide api_key/base_url.
  #
  # Special mail headers `tag`, `stream` and `metadata` are lifted out of
  # the MIME headers and sent as first-class API fields:
  #
  #   mail(to: ..., subject: ..., tag: "receipt", stream: "transactional")
  class Mailer
    # MIME headers that are structural or sent as dedicated API fields —
    # everything else is forwarded via the +headers+ API parameter.
    IGNORED_HEADERS = %w[
      from to cc bcc reply-to subject date message-id mime-version
      content-type content-transfer-encoding return-path received
      tag stream metadata headers
    ].freeze

    attr_accessor :settings

    def initialize(settings = {})
      @settings = settings || {}
    end

    # Delivers a Mail::Message through the CamelMailer API and assigns
    # the resulting message id back onto the mail object.
    def deliver!(mail)
      data = Emails.new(client).send(build_params(mail))
      mail.message_id = data[:message_id].to_s if data.is_a?(Hash) && data[:message_id]
      data
    end

    # Maps a Mail::Message onto a CamelMailer SendRequest hash.
    def build_params(mail)
      params = {
        from: single_address(mail[:from]),
        to: address_list(mail[:to]),
        cc: address_list(mail[:cc]),
        bcc: address_list(mail[:bcc]),
        reply_to: address_list(mail[:reply_to]),
        subject: mail.subject
      }
      params.merge!(contents(mail))
      params.merge!(pseudo_headers(mail))
      headers = custom_headers(mail)
      params[:headers] = headers unless headers.empty?
      attachments = build_attachments(mail)
      params[:attachments] = attachments unless attachments.empty?
      params.compact
    end

    private

    def client
      Client.new(
        api_key: settings[:api_key] || CamelMailer.api_key,
        base_url: settings[:base_url] || CamelMailer.base_url
      )
    end

    def single_address(field)
      address_list(field)&.first
    end

    def address_list(field)
      return nil unless field

      field.addrs.map do |addr|
        if addr.display_name
          { email: addr.address, name: addr.display_name }
        else
          addr.address
        end
      end
    end

    def contents(mail)
      case mail.mime_type
      when "text/html"
        { html_body: mail.body.decoded }
      when "multipart/alternative", "multipart/mixed", "multipart/related"
        multipart_contents(mail)
      else
        { text_body: mail.body.decoded }
      end
    end

    def multipart_contents(mail)
      params = {}
      params[:text_body] = mail.text_part.decoded if mail.text_part
      params[:html_body] = mail.html_part.decoded if mail.html_part
      params
    end

    # Lifts the tag/stream/metadata pseudo-headers into API fields.
    def pseudo_headers(mail)
      params = {}
      params[:tag] = mail["tag"].unparsed_value if mail["tag"]
      params[:stream] = mail["stream"].unparsed_value if mail["stream"]
      params[:metadata] = mail["metadata"].unparsed_value if mail["metadata"]
      params
    end

    def custom_headers(mail)
      mail.header_fields.each_with_object({}) do |field, headers|
        next if IGNORED_HEADERS.include?(field.name.downcase)

        value = field.unparsed_value
        headers[field.name] = value.to_s unless value.nil?
      end
    end

    def build_attachments(mail)
      mail.attachments.map do |part|
        {
          name: part.filename,
          content_type: part.mime_type,
          data_base64: [part.body.decoded].pack("m0")
        }
      end
    end
  end
end
