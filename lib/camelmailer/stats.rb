# frozen_string_literal: true

module CamelMailer
  # Message counters and delivery statistics (/api/v2/server/stats...).
  class Stats < Resource
    expose :get, :deliveries

    # Message counters, optionally windowed with from:/to: (ISO 8601).
    def get(from: nil, to: nil)
      client.get("stats", { from: from, to: to })
    end

    # Delivery/queue statistics.
    def deliveries
      client.get("stats/deliveries")
    end
  end
end
