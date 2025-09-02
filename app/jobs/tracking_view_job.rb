class TrackingViewJob < ApplicationJob
  queue_as :low

  discard_on ActiveRecord::RecordNotFound

  def perform(delivery_id, ip)
    delivery = Delivery.find(delivery_id)

    # Incremento seguro se a coluna existir
    if delivery.attributes.key?('public_views_count')
      Delivery.increment_counter(:public_views_count, delivery.id)
    end

    if delivery.respond_to?(:last_viewed_at=)
      delivery.update_columns(last_viewed_at: Time.current)
    end

    Rails.logger.info("[TrackingView] delivery=#{delivery.id} ip=#{ip}")
  end
end
