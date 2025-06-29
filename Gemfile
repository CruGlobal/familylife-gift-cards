source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem 'rails', '~> 8.0.0'
gem 'rails', '~> 8.0.0'
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
gem "sassc-rails"

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
gem "redis", "~> 4.0"
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

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

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
gem "dogstatsd-ruby", "~> 5.3"
gem "ddtrace", "~> 1.4"

gem "ougai", "~> 1.7"
gem "amazing_print"
gem "strip_attributes"
gem "bundler-audit"
gem "rails-html-sanitizer", "~> 1.6"
gem "lograge"
