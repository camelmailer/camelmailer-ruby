# frozen_string_literal: true

module CamelMailer
  # Broadcast campaigns (/api/v2/server/campaigns...).
  #
  # A campaign is content plus an audience. There are two ways to create
  # one and they behave differently: #create_draft writes it and waits,
  # while #create_and_send expands it to the stream's subscribers before
  # the call returns.
  class Campaigns < Resource
    expose :list, :list_for_stream, :get, :get_for_stream, :create_draft,
           :create_and_send, :update, :send, :cancel

    # Every campaign on the server, newest first.
    def list
      client.get("campaigns")
    end

    # The campaigns of one broadcast stream.
    def list_for_stream(permalink)
      client.get("streams/#{permalink}/campaigns")
    end

    # One campaign together with its statistics.
    def get(id)
      client.get("campaigns/#{id}")
    end

    # One campaign through its stream.
    def get_for_stream(permalink, id)
      client.get("streams/#{permalink}/campaigns/#{id}")
    end

    # Creates a campaign without sending it. Name the audience with
    # stream:. Leave scheduled_at: out for a draft, set it for a
    # scheduled send, or pass send_now: true to send on creation.
    def create_draft(params)
      client.post("campaigns", params)
    end

    # Creates a campaign on a broadcast stream and sends it immediately.
    # The send starts before this call returns, so there is no draft to
    # review and no schedule to set. Use #create_draft when the campaign
    # should wait.
    def create_and_send(permalink, params)
      client.post("streams/#{permalink}/campaigns", params)
    end

    # Updates a draft or scheduled campaign. Setting scheduled_at: moves a
    # draft to scheduled; nil clears the schedule and drops it back to a
    # draft. A campaign that is already sending cannot be edited.
    def update(id, params)
      client.patch("campaigns/#{id}", params)
    end

    # Sends a campaign now, whatever its schedule said.
    def send(id)
      client.post("campaigns/#{id}/send")
    end

    # Cancels a scheduled or in-flight campaign. Messages already queued
    # are not recalled.
    def cancel(id)
      client.post("campaigns/#{id}/cancel")
    end
  end
end
