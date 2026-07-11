# frozen_string_literal: true

require "camelmailer"
require "camelmailer/mailer"

module CamelMailer
  # Registers the :camelmailer ActionMailer delivery method in Rails apps.
  class Railtie < ::Rails::Railtie
    ActiveSupport.on_load(:action_mailer) do
      add_delivery_method :camelmailer, CamelMailer::Mailer
      ActiveSupport.run_load_hooks(:camelmailer_mailer, CamelMailer::Mailer)
    end
  end
end
