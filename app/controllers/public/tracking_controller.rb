class Public::TrackingController < ApplicationController
  layout 'public'

  before_action :set_delivery

  def show
    @current_location = @delivery.current_location
    @estimated_arrival = @delivery.estimated_arrival_time

    # Track page view for analytics
    TrackingViewJob.perform_later(@delivery.id, request.remote_ip)
  end

  private

  def set_delivery
    @delivery = Delivery.find_by!(public_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render 'not_found', status: :not_found
  end
end
