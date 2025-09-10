# Service para gerenciar transições de status de delivery
class DeliveryStatusService
  include Interactor

  def call
    validate_transition!
    update_delivery_status!
    handle_side_effects!
  end

  private

  def validate_transition!
    unless delivery.can_transition_to?(new_status)
      context.fail!(error: "Transição inválida de #{delivery.status} para #{new_status}")
    end
  end

  def update_delivery_status!
    delivery.update!(status: new_status, updated_at: Time.current)
  end

  def handle_side_effects!
    case new_status
    when 'assigned'
      schedule_route_calculation
    when 'en_route'
      start_tracking
    when 'delivered', 'canceled'
      stop_tracking
      complete_delivery
    end
  end

  def schedule_route_calculation
    RouteCalculationJob.perform_later(delivery) if delivery.courier.present?
  end

  def start_tracking
    TrackingViewJob.perform_later(delivery)
  end

  def stop_tracking
    # Lógica para parar tracking em tempo real
  end

  def complete_delivery
    # Lógica para finalizar delivery (relatórios, métricas, etc.)
  end

  def delivery
    context.delivery
  end

  def new_status
    context.status
  end
end
