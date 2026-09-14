# frozen_string_literal: true

module CamelMailer
  # Template layouts (/api/v2/server/layouts...).
  #
  # A layout wraps every template that uses it, so header, footer and
  # styling live in one place instead of in each template.
  class Layouts < Resource
    expose :list, :create, :get, :update, :delete, :upload_logo

    def list
      client.get("layouts")
    end

    # Creates a layout. html_wrapper: has to embed the body with
    # {{{ content }}}; anything else is refused with ValidationError.
    def create(params)
      client.post("layouts", params)
    end

    def get(permalink)
      client.get("layouts/#{permalink}")
    end

    # Updates a layout; only the given fields change.
    def update(permalink, params)
      client.patch("layouts/#{permalink}", params)
    end

    # Deletes a layout. Templates that referenced it fall back to no
    # wrapper.
    def delete(permalink)
      client.delete("layouts/#{permalink}")
    end

    # Uploads the layout's logo as a data URL
    # ("data:image/png;base64,...") and returns the absolute URL to
    # reference from the wrapper.
    def upload_logo(permalink, data_url)
      client.post("layouts/#{permalink}/logo", { data_url: data_url })
    end
  end
end
