source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0", ">= 8.0.5"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
# gem "propshaft" # Not adopted: ActiveAdmin 3.x requires sprockets (revisit at the post-wave AA 4.0 migration); sprockets-rails (below) stays

gem "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 6.0"
gem "redis-actionpack"

# login-related
gem "devise"
gem "omniauth-oktaoauth", github: "CruGlobal/omniauth-oktaoauth"
gem "omniauth-rails_csrf_protection"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
# gem "solid_cache" # Not adopted: Rails.cache is :redis_cache_store
# gem "solid_queue" # Not adopted: no dedicated job backend (Rails default :async adapter)
# gem "solid_cable" # Not adopted: Action Cable uses the redis adapter

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem "kamal", require: false # Not adopted: deploys via Docker on AWS ECS

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # More test-related gems
  gem "database_cleaner-active_record"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
  gem "simplecov-cobertura", require: false
  gem "webmock"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  gem "standard"

  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
end

gem "activeadmin", "~> 3.2"
gem "activeadmin_addons"

gem "aasm"
gem "activerecord-import"
gem "connection_pool", "< 3" # Conflict with redis_cache_store in Rails < 8.1.2
gem "dogstatsd-ruby"
gem "datadog"

gem "ougai", "~> 1.7"
gem "amazing_print"
gem "strip_attributes"
gem "bundler-audit"
gem "rails-html-sanitizer", "~> 1.6"
gem "lograge"
# Asset pipeline: staying on sprockets (propshaft declined above — ActiveAdmin 3.x requires sprockets)
gem "sprockets-rails"
gem "sassc-embedded"
# https://github.com/sass-contrib/sass-embedded-host-ruby/issues/210
gem "google-protobuf", force_ruby_platform: true if RUBY_PLATFORM.include?("linux-musl")
