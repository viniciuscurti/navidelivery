class Api::V1::TrackingController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_delivery, only: [:show, :status]
  before_action :set_cors_headers

  def show
    last_ping = @delivery.current_location
    render json: serialize_full(@delivery, last_ping)
  end

  def status
    last_ping = @delivery.current_location
    render json: serialize_status(@delivery, last_ping)
  end

  private

  def set_delivery
    @delivery = Delivery.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Delivery not found' }, status: :not_found
  end

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  end

  def serialize_full(delivery, last_ping)
    {
      id: delivery.id,
      store: delivery.store ? { name: delivery.store.name } : nil,
      external_order_code: delivery.external_order_code,
      status: delivery.status,
      progress: delivery.respond_to?(:progress_percentage) ? delivery.progress_percentage : nil,
      pickup_address: delivery.pickup_address,
      dropoff_address: delivery.dropoff_address,
      pickup_lat: delivery.pickup_lat,
      pickup_lng: delivery.pickup_lng,
      dropoff_lat: delivery.dropoff_lat,
      dropoff_lng: delivery.dropoff_lng,
      current_location: last_ping&.coordinates,
      route_polyline: delivery.route&.polyline,
      estimated_arrival: delivery.respond_to?(:estimated_arrival_time) ? delivery.estimated_arrival_time&.iso8601 : nil,
      courier: delivery.courier ? { name: delivery.courier.name, phone: delivery.courier.phone } : nil,
      updated_at: delivery.updated_at.iso8601
    }
  end

  def serialize_status(delivery, last_ping)
    {
      status: delivery.status,
      progress: delivery.respond_to?(:progress_percentage) ? delivery.progress_percentage : nil,
      current_location: last_ping&.coordinates,
      estimated_arrival: delivery.respond_to?(:estimated_arrival_time) ? delivery.estimated_arrival_time&.iso8601 : nil,
      updated_at: delivery.updated_at.iso8601
    }
  end
end
