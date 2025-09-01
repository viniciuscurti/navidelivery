module Public
  class TrackingController < ApplicationController
    def show
      @delivery = Delivery.find_by(public_token: params[:public_token])
      render :show
    end
  end
end

