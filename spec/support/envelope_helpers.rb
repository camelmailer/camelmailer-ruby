# frozen_string_literal: true

# Helpers to build CamelMailer API response envelopes in specs.
module EnvelopeHelpers
  BASE = "https://app.camelmailer.com/api/v2/server"

  def success_json(data = {})
    JSON.generate({ status: "success", time: 0.004, data: data })
  end

  def error_json(code, message)
    JSON.generate({ status: "error", time: 0.004, error: { code: code, message: message } })
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  def stub_success(method, path, data: {}, status: 200)
    stub_request(method, "#{BASE}/#{path}")
      .to_return(status: status, body: success_json(data), headers: json_headers)
  end

  def stub_error(method, path, code:, message: "boom", status: 422)
    stub_request(method, "#{BASE}/#{path}")
      .to_return(status: status, body: error_json(code, message), headers: json_headers)
  end

  def configure_key!
    CamelMailer.configure { |c| c.api_key = "cm_test_key" }
  end
end
