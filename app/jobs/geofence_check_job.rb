class GeofenceCheckJob < ApplicationJob
  queue_as :default

  def perform(delivery_id, location_ping_id)
    delivery = Delivery.find(delivery_id)
    ping = LocationPing.find(location_ping_id)

    check_pickup_arrival(delivery, ping)
    check_dropoff_arrival(delivery, ping)
  end

  private

  def check_pickup_arrival(delivery, ping)
    return unless delivery.assigned? || delivery.en_route?

    distance_to_pickup = ping.distance_from(delivery.pickup_lat, delivery.pickup_lng)

    if distance_to_pickup <= geofence_radius && !delivery.arrived_pickup?
      delivery.update!(status: 'arrived_pickup', arrived_pickup_at: Time.current)
      WebhookJob.perform_later(delivery.store.account_id, 'delivery.arrived_pickup', delivery.id)
    end
  end

  def check_dropoff_arrival(delivery, ping)
    return unless delivery.left_pickup?

    distance_to_dropoff = ping.distance_from(delivery.dropoff_lat, delivery.dropoff_lng)

    if distance_to_dropoff <= geofence_radius && !delivery.arrived_dropoff?
      delivery.update!(status: 'arrived_dropoff', arrived_dropoff_at: Time.current)
      WebhookJob.perform_later(delivery.store.account_id, 'delivery.arrived_dropoff', delivery.id)
    end
  end

  def geofence_radius
    ENV.fetch('DEFAULT_GEOFENCE_RADIUS_METERS', 50).to_i
  end
end
