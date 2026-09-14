# frozen_string_literal: true

module CamelMailer
  # The server's own request log and tag index
  # (/api/v2/server/logs, /api/v2/server/tags).
  #
  # Useful when a send did not arrive and the question is whether the
  # request ever reached the API, and with what answer.
  class Logs < Resource
    expose :list, :tags

    # Logged API requests, newest first.
    def list(**filters)
      client.get("logs", filters)
    end

    # Tags used by the server's recent messages, most used first.
    def tags
      client.get("tags")
    end
  end
end
