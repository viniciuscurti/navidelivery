Apartment.configure do |config|
  config.excluded_models = %w{ Account }
  config.tenant_names = lambda { Account.pluck :subdomain }
end

