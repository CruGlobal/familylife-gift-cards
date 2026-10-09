require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/log/logger"
module FamilylifeGiftCards
  # Load-balancer health-check endpoint. Single source of truth: these configs
  # reference the constants and stay in sync automatically:
  #   - config/environments/production.rb   (ssl_options redirect exclude, which compares request.fullpath)
  #   - config/environments/production.rb   (silence_healthcheck_path)
  #   - config/environments/production.rb   (host_authorization exclude)
  #   - config/initializers/lograge.rb      (ignore_actions, which needs the controller#action form)
  #   - config/initializers/datadog.rb      (span filter that drops health-check traces)
  # Intentionally still hardcoded -- a rename must update these by hand:
  #   - config/routes.rb                    (route definition, which needs the path without its leading slash)
  #   - cru-terraform: the ALB target-group health-check path
  HEALTHCHECK_PATH = "/monitors/lb"
  HEALTHCHECK_ACTION = "MonitorsController#lb"

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Eastern Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_storage.variant_processor = :disabled

    redis_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "redis.yml"))).result, permitted_classes: [Symbol], aliases: true)["cache"]
    redis_conf[:url] = "redis://" + redis_conf[:host] + "/" + redis_conf[:db].to_s
    redis_conf[:max_key_size] = 1024
    config.cache_store = :redis_cache_store, redis_conf

    # Send all logs to stdout, which docker reads and sends to datadog.
    config.logger = Log::Logger.new($stdout) unless Rails.env.test? # we don't need a logger in test env
  end
end
