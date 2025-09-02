Rails.application.config.action_dispatch.default_headers.merge!(
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-Content-Type-Options' => 'nosniff',
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Permissions-Policy' => "geolocation=(self), microphone=(), camera=()",
  'X-XSS-Protection' => '0'
)
