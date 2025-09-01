class BroadcastLocationJob < ApplicationJob
  queue_as :default

  def perform(courier_id, location)
    delivery = Delivery.find_by(courier_id: courier_id, status: 'in_progress')
    if delivery
      DeliveryChannel.broadcast_to(delivery, { location: location })
    end
  end
end

