# frozen_string_literal: true

class RealTimeTrackingInteractor < BaseInteractor
  def call
    require_params!(:delivery)

    context.tracking_data = build_tracking_data
  end

  private

  def build_tracking_data
    {
      delivery: delivery_summary,
      route: route_information,
      courier: courier_location,
      eta: estimated_arrival,
      status: delivery_status,
      timeline: delivery_timeline,
      tracking_url: generate_tracking_url
    }
  end

  def delivery_summary
    {
      id: delivery.id,
      external_order_code: delivery.external_order_code,
      status: delivery.status,
      created_at: delivery.created_at.iso8601,
      public_token: delivery.public_token
    }
  end

  def route_information
    return nil unless delivery.route_calculated_at

    {
      calculated_at: delivery.route_calculated_at.iso8601,
      polyline: delivery.route_polyline,
      estimated_distance: format_distance(delivery.estimated_distance),
      estimated_duration: format_duration(delivery.estimated_duration),
      origin: store_location,
      destination: customer_location
    }
  end

  def courier_location
    return nil unless delivery.courier

    last_ping = delivery.courier.location_pings.order(:pinged_at).last
    return nil unless last_ping

    {
      courier_name: delivery.courier.name,
      latitude: last_ping.location.y,
      longitude: last_ping.location.x,
      last_update: last_ping.pinged_at.iso8601,
      heading: calculate_heading(last_ping)
    }
  end

  def estimated_arrival
    return nil unless delivery.estimated_arrival_at

    {
      estimated_at: delivery.estimated_arrival_at.iso8601,
      calculated_at: delivery.eta_calculated_at&.iso8601,
      current_duration: format_duration(delivery.current_estimated_duration),
      is_delayed: delivery.estimated_arrival_at < Time.current
    }
  end

  def delivery_status
    {
      current: delivery.status,
      progress: calculate_delivery_progress,
      updated_at: delivery.updated_at.iso8601
    }
  end

  def delivery_timeline
    timeline = []

    timeline << {
      status: 'created',
      timestamp: delivery.created_at.iso8601,
      description: 'Pedido criado',
      completed: true
    }

    if delivery.courier
      timeline << {
        status: 'assigned',
        timestamp: delivery.updated_at.iso8601,
        description: "Entregador #{delivery.courier.name} designado",
        completed: %w[assigned picked_up en_route arriving delivered].include?(delivery.status)
      }
    end

    timeline << {
      status: 'picked_up',
      timestamp: delivery.picked_up_at&.iso8601,
      description: 'Pedido coletado na loja',
      completed: %w[picked_up en_route arriving delivered].include?(delivery.status)
    }

    timeline << {
      status: 'en_route',
      timestamp: delivery.en_route_at&.iso8601,
      description: 'Entregador a caminho',
      completed: %w[en_route arriving delivered].include?(delivery.status)
    }

    timeline << {
      status: 'arriving',
      timestamp: delivery.arriving_at&.iso8601,
      description: 'Entregador chegando no destino',
      completed: %w[arriving delivered].include?(delivery.status)
    }

    timeline << {
      status: 'delivered',
      timestamp: delivery.delivered_at&.iso8601,
      description: 'Pedido entregue',
      completed: delivery.status == 'delivered'
    }

    timeline
  end

  def delivery
    @delivery ||= context.delivery
  end

  def generate_tracking_url
    base_url = Rails.application.config.frontend_url || 'http://localhost:3001'
    "#{base_url}/track/#{delivery.public_token}"
  end

  def store_location
    return nil unless delivery.store

    {
      name: delivery.store.name,
      address: delivery.pickup_address,
      latitude: delivery.store.latitude,
      longitude: delivery.store.longitude
    }
  end

  def customer_location
    return nil unless delivery.customer

    {
      name: delivery.customer.name,
      address: delivery.dropoff_address,
      latitude: delivery.customer.latitude,
      longitude: delivery.customer.longitude
    }
  end

  def calculate_delivery_progress
    return 0 unless delivery.courier && delivery.estimated_distance
    return 100 if delivery.delivered?

    current_eta = delivery.current_estimated_duration

    if current_eta && delivery.estimated_duration
      progress = (((delivery.estimated_duration - current_eta).to_f / delivery.estimated_duration) * 100).round
      [progress, 0].max
    else
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
  end

  def format_distance(distance_meters)
    return nil unless distance_meters

    if distance_meters < 1000
      "#{distance_meters}m"
    else
      "#{(distance_meters / 1000.0).round(1)}km"
    end
  end

  def format_duration(duration_seconds)
    return nil unless duration_seconds

    hours = duration_seconds / 3600
    minutes = (duration_seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}min"
    else
      "#{minutes}min"
    end
  end

  def calculate_heading(ping)
    0
  end
end
