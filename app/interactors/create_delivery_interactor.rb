require_relative 'base'
require 'securerandom'

class CreateDeliveryInteractor < BaseInteractor
  def call
    require_params!(:account, :delivery_params)
    delivery = context.account.deliveries.new(context.delivery_params)
    delivery.public_token = SecureRandom.hex(10)
    if delivery.save
      context.delivery = delivery
    else
      fail_with_error!(delivery.errors.full_messages)
    end
  end
end
