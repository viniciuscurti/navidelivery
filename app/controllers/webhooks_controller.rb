class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    endpoint = WebhookEndpoint.find_by(url: request.url)
    if endpoint.present?
      # Processa o evento conforme o tipo
      # ...lógica de validação e processamento...
      head :ok
    else
      head :unauthorized
    end
  end
end

