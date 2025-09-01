class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    subdomain = request.host.split('.').first
    if Account.exists?(subdomain: subdomain)
      Apartment::Tenant.switch!(subdomain)
      Current.account = Account.find_by(subdomain: subdomain)
    end
    @app.call(env)
  ensure
    Apartment::Tenant.reset
    Current.account = nil
  end
end

