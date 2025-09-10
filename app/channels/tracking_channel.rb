# frozen_string_literal: true

class TrackingChannel < ApplicationCable::Channel
  def subscribed
    delivery_token = params[:delivery_token]

    if delivery_token.present?
      delivery = Delivery.find_by(public_token: delivery_token)

      if delivery
        stream_from "delivery_#{delivery_token}"

        result = RealTimeTrackingInteractor.call(delivery: delivery)
        if result.success?
          transmit({
            type: 'initial_data',
            data: result.tracking_data
          })
        end

        logger.info "Client subscribed to delivery tracking: #{delivery_token}"
      else
        reject
      end
    else
      reject
    end
  end

  def unsubscribed
    logger.info "Client unsubscribed from delivery tracking"
  end

  def refresh_data
    delivery_token = params[:delivery_token]
    delivery = Delivery.find_by(public_token: delivery_token)

    if delivery
      result = RealTimeTrackingInteractor.call(delivery: delivery)
      if result.success?
        transmit({
          type: 'refresh_data',
          data: result.tracking_data
        })
      end
    end
  end

  def get_current_location
    delivery_token = params[:delivery_token]
    delivery = Delivery.find_by(public_token: delivery_token)

    if delivery&.courier
      result = RealTimeTrackingInteractor.call(delivery: delivery)
      if result.success?
        transmit({
          type: 'current_location',
          data: {
            courier: result.tracking_data[:courier],
            eta: result.tracking_data[:eta]
          }
        })
      end
    end
  end
end
