# frozen_string_literal: true

require_relative "lib/camelmailer/version"

Gem::Specification.new do |spec|
  spec.name          = "camelmailer"
  spec.version       = CamelMailer::VERSION
  spec.summary       = "The Ruby and Rails SDK for Camelmailer"
  spec.description   = "Ruby SDK for the Camelmailer transactional email API — " \
                       "send messages, manage templates, streams and stats, and " \
                       "plug into Rails via the :camelmailer ActionMailer delivery method."
  spec.homepage      = "https://github.com/camelmailer/camelmailer-ruby"
  spec.license       = "MIT"

  spec.authors       = ["Camelmailer contributors"]
  spec.email         = ["hello@camelmailer.com"]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://camelmailer.com/docs",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["lib/**/*.rb", "sig/**/*.rbs", "*.md", "LICENSE"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1"
end
