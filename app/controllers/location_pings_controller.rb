class LocationPingsController < ApplicationController
  def create
    result = ProcessLocationPingInteractor.call(account: Current.account, courier_id: params[:courier_id], location: params[:location])
    if result.success?
      render json: result.ping, status: :created
    else
      render json: { errors: result.error }, status: :unprocessable_entity
    end
  end
end
