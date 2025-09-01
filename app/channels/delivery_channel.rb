class DeliveryChannel < ApplicationCable::Channel
  def subscribed
    delivery = Delivery.find_by(public_token: params[:public_token])
    stream_for delivery if delivery
  end
end

