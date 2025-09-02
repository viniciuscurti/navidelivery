class LocationPingCleanupJob < ApplicationJob
  queue_as :low_priority

  def perform(delivery_id)
    delivery = Delivery.find(delivery_id)

    # Manter apenas os últimos 100 pings por entrega
    old_pings = delivery.location_pings
                       .order(created_at: :desc)
                       .offset(100)

    if old_pings.any?
      deleted_count = old_pings.delete_all
      Rails.logger.info "Cleaned up #{deleted_count} old location pings for delivery #{delivery_id}"
    end

    # Comprimir pings antigos globalmente (executar 1x por dia)
    if should_run_global_cleanup?
      LocationPing.compress_old_pings!
    end
  end

  private

  def should_run_global_cleanup?
    # Executar limpeza global apenas 1x por dia
    Rails.cache.fetch('last_ping_cleanup', expires_in: 1.day) do
      true
    end
  end
end

