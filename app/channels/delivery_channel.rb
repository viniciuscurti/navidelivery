class DeliveryChannel < ApplicationCable::Channel
  def subscribed
    delivery = find_delivery
    return reject unless delivery

    stream_for delivery

    # Send current status immediately
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
    # Cleanup when channel is closed
  end

  private

  def find_delivery
    if params[:public_token]
      # Public access via tracking token
      Delivery.find_by(public_token: params[:public_token])
    elsif params[:delivery_id] && current_account
      # Authenticated access
      current_account.deliveries.find(params[:delivery_id])
    end
  end

  def current_account
    # Extract account from connection if authenticated
    connection.current_account if connection.respond_to?(:current_account)
  end
end
