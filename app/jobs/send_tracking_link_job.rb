class SendTrackingLinkJob < ApplicationJob
  queue_as :notifications

  discard_on ActiveRecord::RecordNotFound

  def perform(delivery_id)
    delivery = Delivery.find(delivery_id)
    return if !delivery.respond_to?(:public_tracking_url) || delivery.public_tracking_url.blank?

    phone = delivery.try(:customer_phone).to_s
    return if phone.blank?

    customer_name = delivery.try(:customer_name)
    WhatsappNotifier.send_tracking_link(phone, delivery.public_tracking_url, customer_name: customer_name)
  end
end
