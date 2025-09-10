source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Security
gem 'rack-attack', '~> 6.7.0'
gem 'rack-cors', '~> 2.0.1'

# Authentication & Authorization
gem 'devise'
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'pundit'

# Background Processing
gem 'sidekiq'

# Geo Features
gem 'rgeo'
gem 'activerecord-postgis-adapter'
gem 'httparty'

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Health checks
gem 'health_check'

# JSON Web Tokens for API authentication
gem 'jwt'

# Pagination
gem 'kaminari'

# Fast JSON serialization
gem 'fast_jsonapi'

# Environment variables management
gem 'figaro'

# Performance and monitoring
gem 'bullet', group: :development
gem 'rack-mini-profiler', group: :development

# API documentation
gem 'rswag'

# Image processing
gem 'image_processing', '~> 1.2'

# Versioning and audit trail
gem 'paper_trail'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
  gem 'vcr'
  gem 'webmock'
  gem 'timecop' # For time testing helpers
  gem 'debug', platforms: %i[ mri windows ]
end

group :development do
  gem 'web-console'
  gem 'annotate'
  gem 'brakeman'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end
