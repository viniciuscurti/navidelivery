# frozen_string_literal: true

class UpdateCourierLocationInteractor < BaseInteractor
  def call
    require_params!(:delivery, :latitude, :longitude)

    validate_delivery_has_courier!
    create_location_ping
    schedule_eta_update
    check_arrival_proximity
    broadcast_location_update
  end

  private

  def validate_delivery_has_courier!
    return if context.delivery.courier

    context.fail!(error: 'Delivery has no courier assigned')
  end

  def create_location_ping
    context.location_ping = context.delivery.courier.location_pings.create!(
      delivery: context.delivery,
      location: "POINT(#{context.longitude} #{context.latitude})",
      pinged_at: Time.current
    )
  end

  def schedule_eta_update
    current_location = { lat: context.latitude, lng: context.longitude }
    GoogleMapsProcessingJob.perform_later('update_eta', context.delivery.id, current_location)
  end

  def check_arrival_proximity
    return unless context.delivery.customer&.geocoded?

    courier_location = { lat: context.latitude, lng: context.longitude }
    destination = context.delivery.customer.location_hash

    proximity_result = CheckArrivalProximityInteractor.call(
      courier_location: courier_location,
      destination: destination,
      delivery: context.delivery
    )

    context.proximity_checked = proximity_result.success?
  end

  def broadcast_location_update
    ActionCable.server.broadcast(
      "delivery_#{context.delivery.public_token}",
      {
        type: 'location_update',
        data: {
          latitude: context.latitude,
          longitude: context.longitude,
          timestamp: Time.current.iso8601,
          progress: calculate_delivery_progress
        }
      }
    )
  end

  def calculate_delivery_progress
    CalculateDeliveryProgressInteractor.call(delivery: context.delivery).progress_percentage
  end
end
