# frozen_string_literal: true

class CalculateDeliveryProgressInteractor < BaseInteractor
  def call
    require_params!(:delivery)

    context.progress_percentage = calculate_progress
  end

  private

  def calculate_progress
    return 0 unless delivery.courier && delivery.estimated_distance
    return 100 if delivery.delivered?

    current_eta = delivery.current_estimated_duration

    if current_eta && delivery.estimated_duration
      progress = (((delivery.estimated_duration - current_eta).to_f / delivery.estimated_duration) * 100).round
      [progress, 0].max
    else
      status_based_progress
    end
  end

  def status_based_progress
    case delivery.status
    when 'created' then 0
    when 'assigned' then 10
    when 'picked_up' then 25
    when 'en_route' then 50
    when 'arriving' then 90
    when 'delivered' then 100
    else 0
    end
  end

  def delivery
    @delivery ||= context.delivery
  end
end
