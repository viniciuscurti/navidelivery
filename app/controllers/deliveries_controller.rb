class DeliveriesController < ApplicationController
  before_action :set_current_account
  before_action :set_delivery, only: [:show, :update, :destroy]

  def index
    authorize Delivery
    @deliveries = policy_scope(DeliveryRepository.for_account(Current.account))
    render json: @deliveries
  end

  def show
    authorize @delivery
    render json: @delivery
  end

  def create
    authorize Delivery
    result = CreateDeliveryInteractor.call(account: Current.account, delivery_params: delivery_params)
    if result.success?
      render json: result.delivery, status: :created
    else
      render json: { errors: result.error }, status: :unprocessable_entity
    end
  end

  def update
    authorize @delivery
    if @delivery.update(delivery_params)
      render json: @delivery
    else
      render json: @delivery.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @delivery
    @delivery.destroy
    head :no_content
  end

  private

  def set_current_account
    Current.account = current_user.account if current_user
  end

  def set_delivery
    @delivery = DeliveryRepository.for_account(Current.account).find(params[:id])
  end

  def delivery_params
    params.require(:delivery).permit(:store_id, :courier_id, :user_id, :status, :pickup_location, :dropoff_location)
  end
end
