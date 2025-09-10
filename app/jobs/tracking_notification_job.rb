# frozen_string_literal: true

class TrackingNotificationJob < ApplicationJob
  queue_as :default

  def perform(delivery_id, event_type, additional_data = {})
    delivery = Delivery.find(delivery_id)

    case event_type.to_s
    when 'courier_assigned'
      notify_courier_assigned(delivery)
    when 'pickup_completed'
      notify_pickup_completed(delivery)
    when 'en_route'
      notify_en_route(delivery)
    when 'arriving'
      notify_arriving(delivery)
    when 'delivered'
      notify_delivered(delivery)
    when 'eta_updated'
      notify_eta_updated(delivery, additional_data)
    end
  end

  private

  def notify_courier_assigned(delivery)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'courier_assigned', {
        courier: result.tracking_data[:courier],
        message: "Entregador #{delivery.courier.name} foi designado para sua entrega"
      })
    end
  end

  def notify_pickup_completed(delivery)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'pickup_completed', {
        status: result.tracking_data[:status],
        message: 'Seu pedido foi coletado e está a caminho'
      })
    end
  end

  def notify_en_route(delivery)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'en_route', {
        eta: result.tracking_data[:eta],
        message: 'Entregador está a caminho do destino'
      })
    end
  end

  def notify_arriving(delivery)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'arriving', {
        courier: result.tracking_data[:courier],
        message: 'Entregador está chegando ao destino'
      })
    end
  end

  def notify_delivered(delivery)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'delivered', {
        status: result.tracking_data[:status],
        message: 'Entrega realizada com sucesso!'
      })
    end
  end

  def notify_eta_updated(delivery, additional_data)
    result = RealTimeTrackingInteractor.call(delivery: delivery)

    if result.success?
      broadcast_update(delivery, 'eta_updated', {
        eta: result.tracking_data[:eta],
        progress: result.tracking_data[:status][:progress],
        message: 'Tempo estimado de chegada atualizado'
      }.merge(additional_data))
    end
  end

  def broadcast_update(delivery, event_type, data)
    ActionCable.server.broadcast(
      "delivery_#{delivery.public_token}",
      {
        type: 'notification',
        event: event_type,
        data: data,
        timestamp: Time.current.iso8601
      }
    )
  end
end
