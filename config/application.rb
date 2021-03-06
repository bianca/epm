require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Epm

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true # http://stackoverflow.com/a/20381730/715538

    config.generators do |g|
      g.test_framework :rspec,
        :view_specs    => false,
        :request_specs => false,
        :controller_specs => false,
        :helper_specs => false,
        :routing_specs => false
    end

    # enables using view helpers in mailer views
    config.to_prepare do
      ActionMailer::Base.helper 'application'
      ActionMailer::Base.helper 'events'
      ActionMailer::Base.helper 'users'
    end

  end

end