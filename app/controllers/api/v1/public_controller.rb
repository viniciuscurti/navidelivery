module Api
  module V1
    class PublicController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!, if: :public_endpoint?

      # GET /api/v1/public/deliveries/:token
      def delivery
        @delivery = Delivery.find_by!(public_token: params[:token])

        render json: {
          id: @delivery.id,
          external_order_code: @delivery.external_order_code,
          status: @delivery.status,
          pickup_lat: @delivery.pickup_lat,
          pickup_lng: @delivery.pickup_lng,
          dropoff_lat: @delivery.dropoff_lat,
          dropoff_lng: @delivery.dropoff_lng,
          dropoff_address: @delivery.dropoff_address,
          current_location: @delivery.current_location&.coordinates,
          estimated_arrival: @delivery.estimated_arrival_time&.iso8601,
          store: {
            name: @delivery.store&.name,
            logo_url: @delivery.store&.logo_url
          },
          courier: {
            name: @delivery.courier&.name,
            phone: @delivery.courier&.phone
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Entrega não encontrada" }, status: :not_found
      end
module Api
  module V1
    class PublicController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :json_request?
      skip_before_action :authenticate_user!, if: :public_endpoint?

      # GET /api/v1/public/deliveries/:token
      def delivery
        @delivery = Delivery.find_by!(public_token: params[:token])

        render json: {
          id: @delivery.id,
          external_order_code: @delivery.external_order_code,
          status: @delivery.status,
          pickup_address: @delivery.pickup_address,
          pickup_lat: @delivery.pickup_lat,
          pickup_lng: @delivery.pickup_lng,
          dropoff_address: @delivery.dropoff_address,
          dropoff_lat: @delivery.dropoff_lat,
          dropoff_lng: @delivery.dropoff_lng,
          current_location: @delivery.current_location&.coordinates,
          estimated_arrival: @delivery.estimated_arrival_time&.iso8601,
          created_at: @delivery.created_at&.iso8601,
          delivered_at: @delivery.delivered_at&.iso8601,
          store: {
            name: @delivery.store&.name,
            logo_url: @delivery.store&.logo_url
          },
          courier: @delivery.courier ? {
            name: @delivery.courier&.name,
            phone: @delivery.courier&.phone
          } : nil
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Entrega não encontrada" }, status: :not_found
      end

      # GET /api/v1/public/deliveries/:token/status
      def delivery_status
        @delivery = Delivery.find_by!(public_token: params[:token])

        render json: {
          status: @delivery.status,
          current_location: @delivery.current_location&.coordinates,
          estimated_arrival: @delivery.estimated_arrival_time&.iso8601,
          updated_at: @delivery.updated_at.iso8601
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Entrega não encontrada" }, status: :not_found
      end

      private

      def public_endpoint?
        action_name.in?(%w[delivery delivery_status])
      end

      def json_request?
        request.format.json? || request.content_type == 'application/json'
      end
    end
  end
end
      # GET /api/v1/public/deliveries/:token/status
      def delivery_status
        @delivery = Delivery.find_by!(public_token: params[:token])

        render json: {
          status: @delivery.status,
          current_location: @delivery.current_location&.coordinates,
          estimated_arrival: @delivery.estimated_arrival_time&.iso8601,
          updated_at: @delivery.updated_at.iso8601
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Entrega não encontrada" }, status: :not_found
      end

      private

      def public_endpoint?
        action_name.in?(%w[delivery delivery_status])
      end
    end
  end
end
