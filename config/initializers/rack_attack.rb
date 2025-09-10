# Configuração do Rack::Attack para rate limiting
class Rack::Attack
  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/auth/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by username
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/auth/sign_in' && req.post?
      req.params['user']['email'].to_s.downcase.gsub(/\s+/, '')
    end
  end

  # Throttle API requests per user
  throttle('api/user', limit: 300, period: 1.hour) do |req|
    if req.path.start_with?('/api/') && req.env['rack.attack.authenticated_user_id']
      req.env['rack.attack.authenticated_user_id']
    end
  end

  # Block requests from known bad IPs
  blocklist('block bad IPs') do |req|
    # You can add known bad IPs here
    # ['192.168.1.1', '10.0.0.1'].include?(req.ip)
    false
  end

  # Allow requests from whitelisted IPs
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Custom response for throttled requests (nova sintaxe)
  self.throttled_responder = lambda do |env|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Too many requests', retry_after: env['rack.attack.match_data'][:period] }.to_json]
    ]
  end

  # Custom response for blocked requests (nova sintaxe)
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Forbidden' }.to_json]
    ]
  end
end

# Log blocked and throttled requests
ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  puts "Rack::Attack: #{name} #{req.env['rack.attack.match_discriminator']} #{req.env['rack.attack.matched']}"
end
