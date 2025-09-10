# frozen_string_literal: true

module Api
  module V1
    module Public
      class TrackingViewController < ApplicationController
        skip_before_action :authenticate_user!, if: :devise_controller?

        before_action :set_delivery
        before_action :validate_tracking_token

        def show
          result = RealTimeTrackingInteractor.call(delivery: @delivery)

          if result.success?
            @tracking_data = result.tracking_data

            respond_to do |format|
              format.html { render 'tracking/show' }
              format.json {
                render json: {
                  success: true,
                  data: @tracking_data
                }
              }
            end
          else
            respond_to do |format|
              format.html {
                flash[:error] = result.error
                redirect_to root_path
              }
              format.json {
                render json: {
                  success: false,
                  error: result.error
                }, status: :unprocessable_entity
              }
            end
          end
        end

        private

        def set_delivery
          @delivery = Delivery.find_by(public_token: params[:token])

          unless @delivery
            render plain: 'Entrega não encontrada', status: :not_found
          end
        end

        def validate_tracking_token
          if @delivery&.status == 'cancelled'
            render plain: 'Esta entrega foi cancelada e não pode ser rastreada', status: :gone
          end
        end
      end
    end
  end
end
