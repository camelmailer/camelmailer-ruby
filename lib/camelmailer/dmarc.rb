# frozen_string_literal: true

module CamelMailer
  # DMARC compliance summary and aggregate reports (/api/v2/server/dmarc...).
  class Dmarc < Resource
    expose :summary, :reports, :report

    # Compliance summary. Filters: domain:, from:, to: (ISO 8601).
    def summary(domain: nil, from: nil, to: nil)
      client.get("dmarc/summary", { domain: domain, from: from, to: to })
    end

    # Stored aggregate reports, newest report range first.
    def reports(domain: nil, from: nil, to: nil, page: nil, per_page: nil)
      client.get("dmarc/reports", { domain: domain, from: from, to: to, page: page, per_page: per_page })
    end

    # One report with its records.
    def report(id)
      client.get("dmarc/reports/#{id}")
    end
  end
end
