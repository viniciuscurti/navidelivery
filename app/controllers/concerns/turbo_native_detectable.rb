# TurboNativeDetectable
#
# Concern para detectar requisições vindas de apps Turbo Native (iOS/Android)
#
# Uso:
#   include TurboNativeDetectable
#   if turbo_native?
#     # lógica customizada para Turbo Native
#   end
#
# Detecta via User-Agent ou header X-Turbo-Native. Pode ser expandido para outros headers.
#
module TurboNativeDetectable
  extend ActiveSupport::Concern

  included do
    before_action :detect_turbo_native
  end

  # Detecta se a requisição veio de um app Turbo Native (iOS/Android)
  def turbo_native?
    user_agent = request.headers["User-Agent"]
    x_turbo_native = request.headers["X-Turbo-Native"]
    # Pode ser expandido para outros headers ou lógicas
    (user_agent&.include?("Turbo Native") || x_turbo_native.present?)
  end

  private

  # Define @turbo_native para uso nas views/controllers
  def detect_turbo_native
    @turbo_native = turbo_native?
  end
end
