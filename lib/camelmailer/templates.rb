# frozen_string_literal: true

module CamelMailer
  # Manage stored message templates (/api/v2/server/templates...).
  class Templates < Resource
    expose :list, :create, :get, :update, :archive, :render

    def list
      client.get("templates")
    end

    # Creates a template. Required: name:. Optional: subject:, html_body:,
    # text_body: — all may contain {{ variables }}.
    def create(params)
      client.post("templates", params)
    end

    def get(permalink)
      client.get("templates/#{permalink}")
    end

    def update(permalink, params)
      client.patch("templates/#{permalink}", params)
    end

    def archive(permalink)
      client.post("templates/#{permalink}/archive")
    end

    # Renders the template against a model without sending anything.
    def render(permalink, template_model = {})
      client.post("templates/#{permalink}/render", { template_model: template_model })
    end
  end
end
