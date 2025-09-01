class Rack::Attack
  # Rate limiting for API endpoints
  throttle('api/ip', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Rate limiting for location pings (higher limit)
  throttle('api/pings', limit: 300, period: 1.minute) do |req|
    req.ip if req.path.include?('/pings')
  end

  # Rate limiting for public tracking pages
  throttle('public/ip', limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/track/')
  end

  # Block requests with suspicious patterns
  blocklist('block suspicious requests') do |req|
    # Block if User-Agent is empty or suspicious
    req.user_agent.blank? ||
      req.user_agent.match?(/bot|crawler|spider/i) && !req.user_agent.match?(/googlebot|bingbot/i)
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{ error: 'Rate limit exceeded' }.to_json]]
  end
end
