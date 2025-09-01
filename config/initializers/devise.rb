# ...arquivo padrão gerado pelo Devise...

Devise.setup do |config|
  config.mailer_sender = 'no-reply@example.com'
  require 'devise/orm/active_record'

  # OmniAuth Google somente se credenciais definidas
  if ENV['GOOGLE_CLIENT_ID'].present? && ENV['GOOGLE_CLIENT_SECRET'].present?
    config.omniauth :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {}
  end

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
end
