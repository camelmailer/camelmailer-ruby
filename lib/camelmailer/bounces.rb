# frozen_string_literal: true

module CamelMailer
  # Read bounce messages (/api/v2/server/bounces...).
  class Bounces < Resource
    expose :list, :get

    # Lists bounces. Filters: page:, per_page: (max 100).
    def list(**filters)
      client.get("bounces", filters)
    end

    def get(id)
      client.get("bounces/#{id}")
    end
  end
end
