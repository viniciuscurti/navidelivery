# Job para notificar mudanças de status de delivery
class DeliveryStatusNotificationJob < ApplicationJob
  queue_as :default

  def perform(delivery)
    # Notificar cliente via WhatsApp
    notify_customer(delivery) if delivery.user.present?

    # Notificar loja
    notify_store(delivery)

    # Webhook para sistemas externos
    trigger_webhook(delivery) if delivery.store.webhook_url.present?
  end

  private

  def notify_customer(delivery)
    return unless delivery.user&.phone.present?

    message = build_customer_message(delivery)
    WhatsappNotifier.send_message(delivery.user.phone, message)
  end

  def notify_store(delivery)
    # Notificar via email ou sistema interno da loja
    StoreMailer.delivery_status_changed(delivery).deliver_now
  end

  def trigger_webhook(delivery)
    WebhookService.new(delivery.store).send_delivery_update(delivery)
  end

  def build_customer_message(delivery)
    case delivery.status
    when 'assigned'
      "Seu pedido #{delivery.external_order_code} foi atribuído a um entregador! 🚚"
    when 'en_route'
      "Seu entregador está a caminho para buscar seu pedido! 🛵"
    when 'delivered'
      "Seu pedido foi entregue com sucesso! ✅ Obrigado por escolher nossos serviços."
    when 'canceled'
      "Infelizmente seu pedido #{delivery.external_order_code} foi cancelado. Entre em contato conosco para mais informações."
    else
      "Status do seu pedido #{delivery.external_order_code} foi atualizado para: #{delivery.status}"
    end
  end
end
