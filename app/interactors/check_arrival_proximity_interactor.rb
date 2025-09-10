# frozen_string_literal: true

class CheckArrivalProximityInteractor < BaseInteractor
  def call
    require_params!(:courier_location, :destination, :delivery)

    calculate_distance
    check_proximity_threshold
    update_delivery_status_if_near
  end

  private

  def calculate_distance
    result = DeliveryRouteInteractor.call(
      action: :courier_near_destination,
      courier_location: context.courier_location,
      destination: context.destination,
      threshold_meters: 100
    )

    if result.success?
      context.is_near = result.is_near
      context.distance_to_destination = result.distance
    else
      context.fail!(error: "Failed to calculate distance: #{result.error}")
    end
  end

  def check_proximity_threshold
    context.within_threshold = context.is_near
  end

  def update_delivery_status_if_near
    return unless context.is_near && context.delivery.status == 'en_route'

    context.delivery.update!(status: 'arriving')
    broadcast_status_update
    schedule_notification
  end

  def broadcast_status_update
    ActionCable.server.broadcast(
      "delivery_#{context.delivery.public_token}",
      {
        type: 'status_update',
        data: {
          status: 'arriving',
          timestamp: Time.current.iso8601
        }
      }
    )
  end

  def schedule_notification
    DeliveryStatusNotificationJob.perform_later(context.delivery.id, 'arriving')
  end
end
