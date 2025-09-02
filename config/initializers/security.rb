# Configurações de segurança
Rails.application.config.force_ssl = true if Rails.env.production?

# Headers de segurança
Rails.application.config.force_ssl = true
Rails.application.config.ssl_options = { redirect: { exclude: ->(request) { request.path =~ /health/ } } }

