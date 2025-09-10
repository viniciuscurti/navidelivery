# frozen_string_literal: true

module Api
  module V1
    module Public
      class TrackingController < ApplicationController
        # Não requer autenticação - endpoint público
        skip_before_action :authenticate_user!, if: :devise_controller?

        before_action :set_delivery, only: [:show, :location_update, :subscribe_updates]
        before_action :validate_tracking_token, only: [:show, :location_update, :subscribe_updates]

        # GET /api/v1/public/track/:token
        # Endpoint público para tracking da entrega
        def show
          result = RealTimeTrackingInteractor.call(delivery: @delivery)

          if result.success?
            render json: {
              success: true,
              data: result.tracking_data
            }
          else
            render json: {
              success: false,
              error: result.error
            }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/public/track/:token/location
        # Atualizar localização do courier (usado pelo app do courier)
        def location_update
          latitude = params[:latitude]
          longitude = params[:longitude]

          if latitude.blank? || longitude.blank?
            render json: { error: 'Latitude and longitude are required' }, status: :bad_request
            return
          end

          result = UpdateCourierLocationInteractor.call(
            delivery: @delivery,
            latitude: latitude.to_f,
            longitude: longitude.to_f
          )

          if result.success?
            progress_result = CalculateDeliveryProgressInteractor.call(delivery: @delivery)

            render json: {
              success: true,
              data: {
                location_ping_id: result.location_ping.id,
                progress: progress_result.progress_percentage
              }
            }
          else
            render json: {
              success: false,
              error: result.error
            }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/public/track/:token/route
        # Obter rota completa com histórico
        def route
          @delivery = Delivery.find_by!(public_token: params[:token])

          route_result = RealTimeTrackingInteractor.call(delivery: @delivery)

          if route_result.success?
            render json: {
              success: true,
              data: {
                route: route_result.tracking_data[:route]
              }
            }
          else
            render json: {
              success: false,
              error: route_result.error
            }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/public/track/:token/timeline
        # Obter timeline da entrega
        def timeline
          @delivery = Delivery.find_by!(public_token: params[:token])

          result = RealTimeTrackingInteractor.call(delivery: @delivery)

          if result.success?
            render json: {
              success: true,
              data: result.tracking_data[:timeline]
            }
          else
            render json: {
              success: false,
              error: result.error
            }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/public/track/:token/subscribe
        # Gerar link para WebSocket subscription
        def subscribe_updates
          render json: {
            success: true,
            data: {
              websocket_channel: "delivery_#{@delivery.public_token}",
              cable_url: cable_url
            }
          }
        end

        private

        def set_delivery
          @delivery = Delivery.find_by(public_token: params[:token])

          unless @delivery
            render json: {
              error: 'Delivery not found',
              message: 'Invalid tracking token'
            }, status: :not_found
          end
        end

        def validate_tracking_token
          # Token público é válido se a entrega existe e não foi cancelada
          if @delivery&.status == 'cancelled'
            render json: {
              error: 'Delivery cancelled',
              message: 'This delivery has been cancelled and cannot be tracked'
            }, status: :gone
          end
        end

        def cable_url
          if Rails.env.production?
            "wss://#{request.host}/cable"
          else
            "ws://#{request.host}:#{request.port}/cable"
          end
        end
      end
    end
  end
end
