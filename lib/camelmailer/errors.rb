# frozen_string_literal: true

module CamelMailer
  # Base error for everything raised by this gem.
  #
  # Exposes the stable API error +code+ (e.g. "ValidationError") and the
  # HTTP +status_code+ of the response, when available.
  class Error < StandardError
    attr_reader :code, :status_code

    def initialize(message = nil, code: nil, status_code: nil)
      super(message)
      @code = code
      @status_code = status_code
    end
  end

  # Raised when the API could not be reached at all (DNS, TCP, TLS, timeouts).
  class ConnectionError < Error; end

  # Raised for any error envelope returned by the API. Specific stable
  # error codes map to subclasses; unknown codes raise APIError itself.
  class APIError < Error
    # Builds the most specific error class for an error envelope.
    def self.for(code:, message:, status_code: nil)
      klass = ERROR_CODE_CLASSES.fetch(code, APIError)
      klass.new(message || code || "CamelMailer API error", code: code, status_code: status_code)
    end
  end

  # 401 — missing or invalid API key.
  class UnauthorizedError < APIError; end

  # 403 — the key is valid but not allowed to do this.
  class ForbiddenError < APIError; end

  # 404 — no such resource.
  class NotFoundError < APIError; end

  # 422 — the request was understood but invalid.
  class ValidationError < APIError; end

  # 400 — a required parameter is missing.
  class ParameterMissingError < APIError; end

  # Unexpected non-envelope response (e.g. a 5xx from a proxy).
  class ServerError < APIError; end

  APIError::ERROR_CODE_CLASSES = {
    "Unauthorized" => UnauthorizedError,
    "Forbidden" => ForbiddenError,
    "NotFound" => NotFoundError,
    "ValidationError" => ValidationError,
    "ParameterMissing" => ParameterMissingError
  }.freeze
end
