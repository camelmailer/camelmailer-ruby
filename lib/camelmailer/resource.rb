# frozen_string_literal: true

module CamelMailer
  # Base class for API resources.
  #
  # Resources are used through a client instance (client.emails.send ...)
  # or through class-level convenience methods (CamelMailer::Emails.send ...)
  # that use the globally configured client.
  class Resource
    # Defines class-level methods that delegate to an instance built
    # from the global configuration (CamelMailer.configure).
    def self.expose(*names)
      names.each do |name|
        define_singleton_method(name) do |*args, **kwargs|
          new.public_send(name, *args, **kwargs)
        end
      end
    end

    attr_reader :client

    def initialize(client = CamelMailer.client)
      @client = client
    end
  end
end
