# frozen_string_literal: true

module Api
  module V1
    class MapsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_delivery, only: [:calculate_route, :update_eta]
      before_action :set_courier, only: [:optimize_route]

      # POST /api/v1/maps/geocode
      def geocode
        address = params[:address]

        if address.blank?
          render json: { error: 'Address parameter is required' }, status: :bad_request
          return
        end

        maps_service = GoogleMapsService.new
        result = maps_service.geocode(address)

        if result[:success]
          location_data = result[:data]['results'].first
          render json: {
            success: true,
            data: {
              address: location_data['formatted_address'],
              latitude: location_data['geometry']['location']['lat'],
              longitude: location_data['geometry']['location']['lng'],
              place_id: location_data['place_id']
            }
          }
        else
          render json: {
            success: false,
            error: result[:error],
            message: result[:message]
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/maps/validate_address
      def validate_address
        address = params[:address]

        if address.blank?
          render json: { error: 'Address parameter is required' }, status: :bad_request
          return
        end

        route_service = DeliveryRouteService.new
        is_valid = route_service.validate_customer_address(address)

        render json: {
          valid: is_valid,
          address: address
        }
      end

      # POST /api/v1/maps/calculate_route
      def calculate_route
        route_service = DeliveryRouteService.new

        # Processar em background para não bloquear a resposta
        GoogleMapsProcessingJob.perform_later('calculate_route', @delivery.id)

        render json: {
          success: true,
          message: 'Route calculation started',
          delivery_id: @delivery.id
        }, status: :accepted
      end

      # POST /api/v1/maps/update_eta
      def update_eta
        current_location = params[:current_location]

        # Processar em background
        GoogleMapsProcessingJob.perform_later('update_eta', @delivery.id, current_location)

        render json: {
          success: true,
          message: 'ETA update started',
          delivery_id: @delivery.id
        }, status: :accepted
      end

      # POST /api/v1/maps/optimize_route
      def optimize_route
        # Processar otimização em background
        GoogleMapsProcessingJob.perform_later('optimize_courier_route', @courier.id)

        render json: {
          success: true,
          message: 'Route optimization started',
          courier_id: @courier.id
        }, status: :accepted
      end

      # GET /api/v1/maps/distance
      def calculate_distance
        origin = params[:origin]
        destination = params[:destination]

        if origin.blank? || destination.blank?
          render json: { error: 'Origin and destination parameters are required' }, status: :bad_request
          return
        end

        route_service = DeliveryRouteService.new
        distance_data = route_service.calculate_distance(origin, destination)

        if distance_data
          render json: {
            success: true,
            data: distance_data
          }
        else
          render json: {
            success: false,
            error: 'Unable to calculate distance'
          }, status: :unprocessable_entity
        end
      end

      private

      def set_delivery
        @delivery = current_user.account.deliveries.find(params[:delivery_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Delivery not found' }, status: :not_found
      end

      def set_courier
        @courier = current_user.account.couriers.find(params[:courier_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Courier not found' }, status: :not_found
      end
    end
  end
end
