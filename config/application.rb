require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Ensure Devise extends ActiveRecord before routes (and devise-jwt) load the User model.
require 'devise/orm/active_record'

module Geneus
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Psych 4 (Ruby 3.1+): YAML в serialized-колонках (в т.ч. audited_changes у audited)
    # не подгружает Date/BigDecimal по умолчанию — без этого PATCH персоны с датами
    # или координатами (decimal) даёт Psych::DisallowedClass.
    config.active_record.yaml_column_permitted_classes = [
      Symbol,
      Date,
      Time,
      BigDecimal,
      ActiveSupport::TimeWithZone,
      ActiveSupport::TimeZone
    ]

    config.hosts << ENV['BACKEND_HOST']

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
