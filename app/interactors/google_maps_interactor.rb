# frozen_string_literal: true

class GoogleMapsInteractor < BaseInteractor
  include HTTParty

  base_uri 'https://maps.googleapis.com/maps/api'

  def call
    validate_api_key!
    setup_httparty_options

    case context.action
    when :geocode
      geocode_address
    when :reverse_geocode
      reverse_geocode_coordinates
    when :distance_matrix
      calculate_distance_matrix
    when :directions
      get_directions
    when :validate_address
      validate_address_format
    when :calculate_eta
      calculate_estimated_arrival
    when :optimize_route
      optimize_delivery_route
    else
      context.fail!(error: "Invalid action: #{context.action}")
    end
  end

  private

  def validate_api_key!
    api_key = ENV['GOOGLE_MAPS_API_KEY']
    context.fail!(error: 'Google Maps API key not configured') if api_key.blank?
    context.api_key = api_key
  end

  def setup_httparty_options
    self.class.default_timeout(10)
    self.class.headers({
      'User-Agent' => "NaviDelivery/1.0 (Ruby #{RUBY_VERSION})",
      'Accept' => 'application/json'
    })
  end

  def geocode_address
    require_params!(:address)

    return context.fail!(error: 'Address cannot be blank') if context.address.blank?

    options = build_request_options(address: context.address)
    result = make_request('/geocode/json', options)

    if result[:success]
      context.geocoding_result = result[:data]
    else
      context.fail!(error: result[:message])
    end
  end

  def reverse_geocode_coordinates
    require_params!(:latitude, :longitude)

    unless valid_coordinates?(context.latitude, context.longitude)
      return context.fail!(error: 'Invalid coordinates')
    end

    options = build_request_options(latlng: "#{context.latitude},#{context.longitude}")
    result = make_request('/geocode/json', options)

    if result[:success]
      context.reverse_geocoding_result = result[:data]
    else
      context.fail!(error: result[:message])
    end
  end

  def calculate_distance_matrix
    require_params!(:origins, :destinations)

    if context.origins.empty? || context.destinations.empty?
      return context.fail!(error: 'Origins and destinations cannot be empty')
    end

    query_params = {
      origins: format_locations(context.origins),
      destinations: format_locations(context.destinations),
      units: context.units || 'metric',
      mode: context.mode || 'driving',
      traffic_model: context.traffic_model || 'best_guess',
      departure_time: context.departure_time || 'now'
    }

    options = build_request_options(query_params)
    result = make_request('/distancematrix/json', options)

    if result[:success]
      context.distance_matrix_result = result[:data]
    else
      context.fail!(error: result[:message])
    end
  end

  def get_directions
    require_params!(:origin, :destination)

    if context.origin.blank? || context.destination.blank?
      return context.fail!(error: 'Origin and destination cannot be blank')
    end

    query_params = build_directions_params
    options = build_request_options(query_params)
    result = make_request('/directions/json', options)

    if result[:success]
      context.directions_result = result[:data]
    else
      context.fail!(error: result[:message])
    end
  end

  def validate_address_format
    require_params!(:address)

    geocode_result = GoogleMapsInteractor.call(action: :geocode, address: context.address)

    if geocode_result.success?
      results = geocode_result.geocoding_result['results']
      if results.empty?
        context.address_valid = false
      else
        first_result = results.first
        location_type = first_result.dig('geometry', 'location_type')
        context.address_valid = %w[ROOFTOP RANGE_INTERPOLATED].include?(location_type)
      end
    else
      context.address_valid = false
    end
  end

  def calculate_estimated_arrival
    require_params!(:origin, :destination)

    distance_result = GoogleMapsInteractor.call(
      action: :distance_matrix,
      origins: [context.origin],
      destinations: [context.destination],
      units: context.units,
      mode: context.mode,
      traffic_model: context.traffic_model
    )

    if distance_result.success?
      elements = distance_result.distance_matrix_result.dig('rows', 0, 'elements', 0)
      if elements&.dig('status') == 'OK'
        context.eta_data = {
          distance: elements['distance'],
          duration: elements['duration'],
          duration_in_traffic: elements['duration_in_traffic']
        }
      else
        context.eta_data = nil
      end
    else
      context.fail!(error: distance_result.error)
    end
  end

  def optimize_delivery_route
    require_params!(:origin, :destination)

    waypoints = context.waypoints || []

    if waypoints.empty?
      get_directions
    else
      context.optimize = true
      context.waypoints = waypoints
      get_directions
    end
  end

  def build_directions_params
    params = {
      origin: format_location(context.origin),
      destination: format_location(context.destination),
      mode: context.mode || 'driving',
      optimize: context.optimize || false,
      traffic_model: context.traffic_model || 'best_guess',
      departure_time: context.departure_time || 'now'
    }

    if context.waypoints.present?
      formatted_waypoints = context.waypoints.map { |wp| format_location(wp) }.join('|')
      params[:waypoints] = formatted_waypoints
    end

    params
  end

  def build_request_options(params)
    {
      query: params.merge(key: context.api_key),
      timeout: 10
    }
  end

  def make_request(endpoint, options)
    response = self.class.get(endpoint, options)
    handle_response(response)
  rescue Net::TimeoutError => e
    { success: false, message: "Request timeout: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Request failed: #{e.message}" }
  end

  def handle_response(response)
    unless response.success?
      return { success: false, message: "HTTP #{response.code}: #{response.message}" }
    end

    begin
      body = response.parsed_response
      validate_api_response(body)
    rescue JSON::ParserError => e
      { success: false, message: "Failed to parse response: #{e.message}" }
    end
  end

  def validate_api_response(data)
    case data['status']
    when 'OK'
      { success: true, data: data }
    when 'ZERO_RESULTS'
      { success: false, message: 'No results found' }
    when 'OVER_QUERY_LIMIT'
      { success: false, message: 'API quota exceeded' }
    when 'REQUEST_DENIED'
      { success: false, message: data['error_message'] || 'Request denied by API' }
    when 'INVALID_REQUEST'
      { success: false, message: data['error_message'] || 'Invalid request parameters' }
    else
      { success: false, message: data['error_message'] || 'Unknown API error' }
    end
  end

  def valid_coordinates?(lat, lng)
    return false unless lat.is_a?(Numeric) && lng.is_a?(Numeric)

    lat.between?(-90, 90) && lng.between?(-180, 180)
  end

  def format_locations(locations)
    locations.map { |location| format_location(location) }.join('|')
  end

  def format_location(location)
    case location
    when String
      location.strip
    when Hash
      format_hash_location(location)
    when Array
      format_array_location(location)
    else
      location.to_s
    end
  end

  def format_hash_location(location)
    if location[:lat] && location[:lng]
      "#{location[:lat]},#{location[:lng]}"
    elsif location[:latitude] && location[:longitude]
      "#{location[:latitude]},#{location[:longitude]}"
    else
      location[:address] || location['address'] || ''
    end
  end

  def format_array_location(location)
    return '' unless location.length >= 2

    "#{location[0]},#{location[1]}"
  end
end
