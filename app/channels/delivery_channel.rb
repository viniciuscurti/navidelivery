class DeliveryChannel < ApplicationCable::Channel
  def subscribed
    delivery = find_delivery
    return reject unless delivery

    stream_for delivery

    transmit({
               type: 'initial_state',
               delivery: {
                 id: delivery.id,
                 status: delivery.status,
                 current_location: delivery.current_location&.coordinates,
                 estimated_arrival: delivery.estimated_arrival_time&.iso8601
               }
             })
  end

  def unsubscribed
  end

  private

  def find_delivery
    if params[:public_token]
      Delivery.find_by(public_token: params[:public_token])
    elsif params[:delivery_id] && current_account
      current_account.deliveries.find(params[:delivery_id])
    end
  end

  def current_account
    connection.current_account if connection.respond_to?(:current_account)
  end
end
