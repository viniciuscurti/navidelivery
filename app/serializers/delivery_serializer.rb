class DeliverySerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :external_order_code, :status, :created_at, :updated_at

  attributes :pickup_address, :dropoff_address
  attributes :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng
  attributes :estimated_arrival_time, :public_token

  attribute :pickup_coordinates do |delivery|
    [delivery.pickup_lat, delivery.pickup_lng] if delivery.pickup_lat && delivery.pickup_lng
  end

  attribute :dropoff_coordinates do |delivery|
    [delivery.dropoff_lat, delivery.dropoff_lng] if delivery.dropoff_lat && delivery.dropoff_lng
  end

  attribute :public_tracking_url do |delivery|
    Rails.application.routes.url_helpers.api_v1_deliveries_track_url(token: delivery.public_token)
  end

  belongs_to :store, serializer: StoreSerializer
  belongs_to :courier, serializer: CourierSerializer, if: proc { |record| record.courier.present? }
  has_many :location_pings, serializer: LocationPingSerializer

  attribute :current_location do |delivery|
    if delivery.current_location
      {
        lat: delivery.current_location.latitude,
        lng: delivery.current_location.longitude,
        timestamp: delivery.current_location.created_at.iso8601
      }
    end
  end

  attribute :route_info do |delivery|
    if delivery.respond_to?(:route_distance_meters) && delivery.route_distance_meters
      {
        distance_meters: delivery.route_distance_meters,
        duration_seconds: delivery.route_duration_seconds,
        polyline: delivery.route_polyline
      }
    end
  end
end
