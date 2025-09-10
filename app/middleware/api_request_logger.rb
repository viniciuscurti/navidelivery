# Custom middleware for API request logging
class ApiRequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless api_request?(env)

    request = Rack::Request.new(env)
    start_time = Time.current

    status, headers, response = @app.call(env)

    duration = ((Time.current - start_time) * 1000).round(2)

    log_request(request, status, duration)

    [status, headers, response]
  end

  private

  def api_request?(env)
    env['PATH_INFO'].start_with?('/api/')
  end

  def log_request(request, status, duration)
    user_id = request.env['rack.attack.authenticated_user_id'] || 'anonymous'

    Rails.logger.info({
      type: 'api_request',
      method: request.request_method,
      path: request.path,
      status: status,
      duration_ms: duration,
      ip: request.ip,
      user_agent: request.user_agent,
      user_id: user_id,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end
