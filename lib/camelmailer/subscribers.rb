# frozen_string_literal: true

require "uri"

module CamelMailer
  # Opt-in subscribers of a broadcast stream
  # (/api/v2/server/streams/:permalink/subscribers...).
  #
  # A broadcast send to an address that is not subscribed is refused, so
  # this list is the audience.
  class Subscribers < Resource
    expose :list, :add, :import, :complaint, :remove

    # The stream's subscribers, subscribed and unsubscribed alike.
    def list(permalink)
      client.get(base(permalink))
    end

    # Adds or updates one subscriber. Upserts by address:, so calling it
    # twice is safe. Takes address: (required) and status: (:subscribed by
    # default, or :unsubscribed); there is no name field.
    def add(permalink, params)
      client.post(base(permalink), params)
    end

    # Adds many addresses at once, all as subscribed. Blanks and
    # duplicates within the request are skipped, and the response reports
    # how many were written against how many survived that filtering.
    def import(permalink, addresses)
      client.post("#{base(permalink)}/import", { addresses: addresses })
    end

    # Records a spam complaint: writes a stream-scoped suppression and
    # flips the subscription to unsubscribed. Idempotent, so a feedback
    # loop can replay it safely.
    def complaint(permalink, address)
      client.post("#{base(permalink)}/#{encode(address)}/complaint")
    end

    # Removes a subscriber from the stream entirely.
    def remove(permalink, address)
      client.delete("#{base(permalink)}/#{encode(address)}")
    end

    private

    def base(permalink)
      "streams/#{permalink}/subscribers"
    end

    # The plus in an address has to survive the path, or a different
    # address is addressed.
    def encode(address)
      URI.encode_www_form_component(address).gsub("+", "%2B")
    end
  end
end
