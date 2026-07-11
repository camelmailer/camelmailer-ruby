# frozen_string_literal: true

module CamelMailer
  # Manage message streams (/api/v2/server/streams...).
  class Streams < Resource
    expose :list, :create, :get, :update, :archive

    def list
      client.get("streams")
    end

    # Creates a stream. Required: name:. Optional: stream_type:
    # ("transactional" or "broadcast").
    def create(params)
      client.post("streams", params)
    end

    def get(permalink)
      client.get("streams/#{permalink}")
    end

    def update(permalink, params)
      client.patch("streams/#{permalink}", params)
    end

    def archive(permalink)
      client.post("streams/#{permalink}/archive")
    end
  end
end
