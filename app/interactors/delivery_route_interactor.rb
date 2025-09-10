# frozen_string_literal: true

class DeliveryRouteInteractor < BaseInteractor
  def call
    case context.action
    when :calculate_delivery_route
      calculate_delivery_route
    when :calculate_delivery_eta
      calculate_delivery_eta
    when :optimize_multiple_deliveries
      optimize_multiple_deliveries
    when :courier_near_destination
      check_courier_near_destination
    else
      context.fail!(error: "Invalid action: #{context.action}")
    end
  end

  private

  def calculate_delivery_route
    require_params!(:delivery)

    origin = extract_location(context.delivery.store)
    destination = extract_location(context.delivery.customer)

    result = GoogleMapsInteractor.call(
      action: :directions,
      origin: origin,
      destination: destination
    )

    if result.success?
      route_data = parse_route_data(result.directions_result)
      update_delivery_route_info(context.delivery, route_data)
      context.route_data = route_data
    else
      context.fail!(error: "Failed to calculate route: #{result.error}")
    end
  end

  def calculate_delivery_eta
    require_params!(:delivery)

    origin = context.current_location || extract_location(context.delivery.courier)
    destination = extract_location(context.delivery.customer)

    return context.fail!(error: 'Origin or destination not available') unless origin && destination

    result = GoogleMapsInteractor.call(
      action: :calculate_eta,
      origin: origin,
      destination: destination,
      mode: 'driving'
    )

    if result.success?
      update_delivery_eta(context.delivery, result.eta_data)
      context.eta_data = result.eta_data
    else
      context.fail!(error: "Failed to calculate ETA: #{result.error}")
    end
  end

  def optimize_multiple_deliveries
    require_params!(:courier, :deliveries)

    return context.fail!(error: 'No deliveries to optimize') if context.deliveries.empty?

    origin = extract_location(context.courier)
    waypoints = context.deliveries.map { |delivery| extract_location(delivery.customer) }
    destination = waypoints.pop

    result = GoogleMapsInteractor.call(
      action: :optimize_route,
      origin: origin,
      destination: destination,
      waypoints: waypoints
    )

    if result.success?
      context.optimized_route = parse_optimized_route(result.directions_result, context.deliveries)
    else
      context.fail!(error: "Failed to optimize route: #{result.error}")
    end
  end

  def check_courier_near_destination
    require_params!(:courier_location, :destination)

    threshold = context.threshold_meters || 100

    result = GoogleMapsInteractor.call(
      action: :distance_matrix,
      origins: [context.courier_location],
      destinations: [context.destination]
    )

    if result.success?
      distance = extract_distance_from_matrix(result.distance_matrix_result)
      context.distance = distance
      context.is_near = distance && distance <= threshold
    else
      context.fail!(error: "Failed to check proximity: #{result.error}")
    end
  end

  def extract_location(object)
    return nil unless object

    if object.respond_to?(:latitude) && object.respond_to?(:longitude)
      return nil unless object.latitude && object.longitude
      { lat: object.latitude, lng: object.longitude }
    elsif object.is_a?(Hash)
      object
    else
      nil
    end
  end

  def parse_route_data(directions_result)
    route = directions_result['routes']&.first
    return {} unless route

    leg = route['legs']&.first
    return {} unless leg

    {
      polyline: route.dig('overview_polyline', 'points'),
      distance: leg.dig('distance', 'value'),
      duration: leg.dig('duration', 'value'),
      distance_text: leg.dig('distance', 'text'),
      duration_text: leg.dig('duration', 'text'),
      start_address: leg['start_address'],
      end_address: leg['end_address']
    }
  end

  def parse_optimized_route(directions_result, deliveries)
    route = directions_result['routes']&.first
    return [] unless route

    waypoint_order = route['waypoint_order'] || []
    ordered_deliveries = waypoint_order.map { |index| deliveries[index] }

    {
      deliveries: ordered_deliveries,
      total_distance: route['legs'].sum { |leg| leg.dig('distance', 'value') || 0 },
      total_duration: route['legs'].sum { |leg| leg.dig('duration', 'value') || 0 },
      polyline: route.dig('overview_polyline', 'points')
    }
  end

  def update_delivery_route_info(delivery, route_data)
    delivery.update!(
      route_polyline: route_data[:polyline],
      estimated_distance: route_data[:distance],
      estimated_duration: route_data[:duration],
      route_calculated_at: Time.current
    )
  end

  def update_delivery_eta(delivery, eta_data)
    return unless eta_data

    duration = eta_data.dig(:duration, 'value')
    estimated_arrival = Time.current + duration.seconds if duration

    delivery.update!(
      current_estimated_duration: duration,
      estimated_arrival_at: estimated_arrival,
      eta_calculated_at: Time.current
    )
  end

  def extract_distance_from_matrix(matrix_result)
    element = matrix_result.dig('rows', 0, 'elements', 0)
    return nil unless element&.dig('status') == 'OK'

    element.dig('distance', 'value')
  end
end
