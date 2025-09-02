# Concern para otimizações mobile (Hotwire Native)
module MobileOptimized
  extend ActiveSupport::Concern
module MobileOptimized
  extend ActiveSupport::Concern

  included do
    before_action :set_mobile_headers
  end

  private

  def set_mobile_headers
    # Headers úteis para APIs: evitar cache de respostas mutáveis
    if request.format.json? || request.path.start_with?('/api/')
      response.set_header('Cache-Control', 'no-store')
    end
  end
end
  included do
    before_action :detect_mobile_app
    before_action :set_mobile_headers
  end

  private

  def detect_mobile_app
    @is_mobile_app = request.user_agent&.include?('Hotwire Native') ||
                     request.headers['X-Hotwire-Native'].present?
  end

  def set_mobile_headers
    if @is_mobile_app
      response.headers['X-Hotwire-Native-Bridge'] = 'true'
      response.headers['Cache-Control'] = 'no-cache, no-store'
    end
  end

  def mobile_app?
    @is_mobile_app
  end

  def render_for_mobile(template: nil, **options)
    if mobile_app?
      # Renderizar versão otimizada para mobile
      render template: "#{template}_mobile", **options
    else
      render **options
    end
  end
end

