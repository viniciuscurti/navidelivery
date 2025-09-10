# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'pundit/rspec'
require 'webmock/rspec'
require 'vcr'
require 'simplecov'
require 'timecop'

# SimpleCov configuration
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Interactors', 'app/interactors'
  add_group 'Serializers', 'app/serializers'

  minimum_coverage 80
end

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  # Filter sensitive data
  config.filter_sensitive_data('<MAPS_API_KEY>') { ENV['MAPS_API_KEY'] }
  config.filter_sensitive_data('<WHATSAPP_API_TOKEN>') { ENV['WHATSAPP_API_TOKEN'] }
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # FactoryBot integration
  config.include FactoryBot::Syntax::Methods

  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner.allow_remote_database_url = true
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Pundit helpers
  config.include Pundit::RSpec::DSL, type: :policy

  # Use transactional fixtures
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Configure API request helpers
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Disable external HTTP requests in tests
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # Custom helpers for API tests
  config.include Module.new {
    def json_response
      JSON.parse(response.body)
    end

    def auth_headers(user)
      token = JWT.encode(
        { user_id: user.id, exp: 1.hour.from_now.to_i },
        Rails.application.credentials.jwt_secret || 'test_secret',
        'HS256'
      )
      { 'Authorization' => "Bearer #{token}" }
    end
  }, type: :request
end
