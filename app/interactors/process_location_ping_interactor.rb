require 'interactor'
require_relative 'base'

class ProcessLocationPingInteractor < BaseInteractor
  def call
    require_params!(:account, :courier_id, :location)
    courier = context.account.couriers.find(context.courier_id)

    active_delivery = Delivery.in_progress.find_by(courier_id: courier.id)

    ping = courier.location_pings.create!(
      location: context.location,
      pinged_at: Time.current,
      delivery: active_delivery
    )
    GeofenceCheckJob.perform_later(courier.id, ping.location)
    context.ping = ping
  rescue ActiveRecord::RecordNotFound => e
    fail_with_error!(e.message)
  end
end
