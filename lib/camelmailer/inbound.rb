# frozen_string_literal: true

module CamelMailer
  # Inbound and held messages (/api/v2/server/inbound...).
  #
  # Covers mail arriving through an inbound route as well as outbound mail
  # the spam filter put on hold, which is why a message here can be either
  # retried or released past the hold.
  class Inbound < Resource
    expose :list, :get, :retry, :bypass

    # Searches inbound and held messages, newest first.
    def list(**filters)
      client.get("inbound", filters)
    end

    def get(id)
      client.get("inbound/#{id}")
    end

    # Puts a message back on the delivery queue, for instance after fixing
    # the route it should have matched. The response carries :requeued and
    # the :message as it now stands.
    def retry(id)
      client.post("inbound/#{id}/retry")
    end

    # Releases a held message past the hold and delivers it.
    def bypass(id)
      client.post("inbound/#{id}/bypass")
    end
  end
end
