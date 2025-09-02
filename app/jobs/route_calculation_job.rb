class RouteCalculationJob < ApplicationJob
  queue_as :routing

  retry_on StandardError, attempts: 5, wait: :exponentially_longer

  def perform(delivery_id)
    delivery = Delivery.find(delivery_id)

    pickup = [delivery.try(:pickup_lat), delivery.try(:pickup_lng)]
    dropoff = [delivery.try(:dropoff_lat), delivery.try(:dropoff_lng)]

    return unless pickup.compact.size == 2 && dropoff.compact.size == 2

    route = MapService.calculate_route(pickup, dropoff)
    return unless route

    updates = {}

    if delivery.respond_to?(:route_polyline=)
      updates[:route_polyline] = route[:polyline]
    end
    if delivery.respond_to?(:route_distance_meters=)
      updates[:route_distance_meters] = route[:distance_meters]
    end
    if delivery.respond_to?(:route_duration_seconds=)
      updates[:route_duration_seconds] = route[:duration_seconds]
    end
    if delivery.respond_to?(:estimated_arrival_time=) && route[:duration_seconds]
      updates[:estimated_arrival_time] = Time.current + route[:duration_seconds].to_i
    end

    delivery.update_columns(updates) unless updates.empty?
  end
end
