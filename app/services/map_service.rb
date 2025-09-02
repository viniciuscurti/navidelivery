# Serviço centralizado para operações de mapa
class MapService
  include Singleton

  # Usar OpenStreetMap + OSRM (100% gratuito)
  TILE_SERVERS = %w[https://tile.openstreetmap.org/{z}/{x}/{y}.png https://a.tile.openstreetmap.org/{z}/{x}/{y}.png https://b.tile.openstreetmap.org/{z}/{x}/{y}.png https://c.tile.openstreetmap.org/{z}/{x}/{y}.png].freeze

  ROUTING_SERVICE = 'https://router.project-osrm.org'

  def self.tile_url
    TILE_SERVERS.sample
  end

  def self.calculate_route(pickup_coords, dropoff_coords)
    url = "#{ROUTING_SERVICE}/route/v1/driving/#{pickup_coords[1]},#{pickup_coords[0]};#{dropoff_coords[1]},#{dropoff_coords[0]}"
    params = {
      overview: 'full',
      geometries: 'polyline',
      steps: 'false'
    }

    response = HTTParty.get(url, query: params, timeout: 10)

    if response.success? && response['routes']&.any?
      route_data = response['routes'].first
      {
        polyline: route_data['geometry'],
        distance_meters: route_data['distance'].to_i,
        duration_seconds: route_data['duration'].to_i
      }
    else
      # Fallback: linha reta com estimativa
      distance = Geospatial.distance_between(pickup_coords, dropoff_coords)
      {
        polyline: nil,
        distance_meters: distance.to_i,
        duration_seconds: (distance / 30 * 60).to_i # 30 km/h média
      }
    end
  rescue => e
    Rails.logger.error "Route calculation failed: #{e.message}"
    nil
  end

  def self.reverse_geocode(lat, lng)
    # Usar Nominatim (gratuito) para geocoding reverso
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
      format: 'json',
      lat: lat,
      lon: lng,
      zoom: 18,
      addressdetails: 1
    }

    response = HTTParty.get(url, query: params, timeout: 5)
    response.success? ? response['display_name'] : nil
  rescue => e
    Rails.logger.error "Reverse geocoding failed: #{e.message}"
    nil
  end
end
